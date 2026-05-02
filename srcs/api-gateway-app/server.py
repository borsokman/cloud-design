import logging
import os

# Create the logs directory if it doesn't exist
os.makedirs('/app/logs', exist_ok=True)

# Configure logging to write to the file
logging.basicConfig(
    filename='/app/logs/gateway.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s: %(message)s'
)

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)