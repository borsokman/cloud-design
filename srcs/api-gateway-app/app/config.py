import os
from dotenv import load_dotenv

load_dotenv()

INVENTORY_URL = os.getenv("INVENTORY_URL", "http://192.168.56.20:8080")
RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "192.168.56.30")
RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
RABBITMQ_USER = os.getenv("RABBITMQ_USER", "billing_user")
RABBITMQ_PASSWORD = os.getenv("RABBITMQ_PASSWORD", "billing_pass")