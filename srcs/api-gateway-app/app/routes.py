import json
import requests
import pika
from flask import Blueprint, request, jsonify
from app.config import (
    INVENTORY_URL,
    RABBITMQ_HOST,
    RABBITMQ_PORT,
    RABBITMQ_USER,
    RABBITMQ_PASSWORD,
)

gateway_bp = Blueprint("gateway", __name__)


@gateway_bp.route("/api/movies", defaults={"path": ""}, methods=["GET", "POST", "DELETE"])
@gateway_bp.route("/api/movies/<path:path>", methods=["GET", "PUT", "DELETE"])
def proxy_inventory(path):
    target = f"{INVENTORY_URL}/api/movies"
    if path:
        target = f"{target}/{path}"

    try:
        resp = requests.request(
            method=request.method,
            url=target,
            params=request.args,
            json=request.get_json(silent=True),
            timeout=10,
        )
    except requests.RequestException:
        return jsonify({"error": "inventory service unavailable"}), 502

    excluded = {"content-encoding", "transfer-encoding", "connection"}
    headers = [(k, v) for k, v in resp.headers.items() if k.lower() not in excluded]
    return resp.content, resp.status_code, headers


@gateway_bp.route("/api/billing", methods=["POST"])
def post_billing():
    payload = request.get_json(silent=True)
    if payload is None:
        return jsonify({"error": "invalid JSON body"}), 400

    required_fields = ["user_id", "number_of_items", "total_amount"]
    missing = [field for field in required_fields if field not in payload]
    if missing:
        return jsonify({"error": f"missing required fields: {', '.join(missing)}"}), 400

    try:
        # Strict type normalization (fail fast)
        normalized_payload = {
            "user_id": str(payload["user_id"]).strip(),
            "number_of_items": int(payload["number_of_items"]),
            "total_amount": float(payload["total_amount"]),
        }
    except (TypeError, ValueError):
        return jsonify({"error": "invalid field types in billing payload"}), 400

    if not normalized_payload["user_id"]:
        return jsonify({"error": "user_id cannot be empty"}), 400
    if normalized_payload["number_of_items"] <= 0:
        return jsonify({"error": "number_of_items must be > 0"}), 400
    if normalized_payload["total_amount"] < 0:
        return jsonify({"error": "total_amount must be >= 0"}), 400

    connection = None
    try:
        credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASSWORD)
        params = pika.ConnectionParameters(
            host=RABBITMQ_HOST,
            port=RABBITMQ_PORT,
            credentials=credentials,
        )
        connection = pika.BlockingConnection(params)
        channel = connection.channel()
        channel.queue_declare(queue="billing_queue", durable=True)
        channel.basic_publish(
            exchange="",
            routing_key="billing_queue",
            body=json.dumps(normalized_payload),
            properties=pika.BasicProperties(delivery_mode=2),
        )
    except pika.exceptions.AMQPError:
        return jsonify({"error": "billing queue unavailable"}), 503
    finally:
        if connection and connection.is_open:
            connection.close()

    return jsonify({"message": "Message posted"}), 202