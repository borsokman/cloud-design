import os
import json
import time
import pika
from app import db
from app.models import Order


def callback(app, ch, method, properties, body):
    try:
        data = json.loads(body.decode("utf-8"))

        user_id = str(data["user_id"]).strip()
        number_of_items = int(data["number_of_items"])
        total_amount = float(data["total_amount"])

        if not user_id:
            raise ValueError("user_id cannot be empty")
        if number_of_items <= 0:
            raise ValueError("number_of_items must be > 0")
        if total_amount < 0:
            raise ValueError("total_amount must be >= 0")

        with app.app_context():
            order = Order(
                user_id=user_id,
                number_of_items=number_of_items,
                total_amount=total_amount,
            )
            db.session.add(order)
            db.session.commit()

        # Ack only after successful DB commit
        ch.basic_ack(delivery_tag=method.delivery_tag)

    except (json.JSONDecodeError, KeyError, TypeError, ValueError):
        # Invalid payload -> do not requeue (poison message)
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

    except Exception:
        # Transient/server error -> requeue for retry
        with app.app_context():
            db.session.rollback()
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)


def run_consumer(app):
    rabbit_host = os.getenv("RABBITMQ_HOST", "localhost")
    rabbit_port = int(os.getenv("RABBITMQ_PORT", "5672"))
    rabbit_user = os.getenv("RABBITMQ_USER", "guest")
    rabbit_password = os.getenv("RABBITMQ_PASSWORD", "guest")

    credentials = pika.PlainCredentials(rabbit_user, rabbit_password)
    params = pika.ConnectionParameters(
        host=rabbit_host,
        port=rabbit_port,
        credentials=credentials,
        heartbeat=60,
        blocked_connection_timeout=30,
    )

    while True:
        connection = None
        try:
            connection = pika.BlockingConnection(params)
            channel = connection.channel()
            channel.queue_declare(queue="billing_queue", durable=True)
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(
                queue="billing_queue",
                on_message_callback=lambda ch, method, properties, body: callback(
                    app, ch, method, properties, body
                ),
            )
            channel.start_consuming()

        except pika.exceptions.AMQPError:
            # Broker unavailable / connection dropped
            time.sleep(5)

        finally:
            if connection and connection.is_open:
                connection.close()