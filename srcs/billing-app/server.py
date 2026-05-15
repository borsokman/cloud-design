from app import create_app
from app.consumer import run_consumer

app = create_app()

if __name__ == "__main__":
    run_consumer(app)