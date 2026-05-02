from app import create_app

app = create_app()

if __name__ == "__main__":
    # Runs the app on port 8080, accessible from anywhere (0.0.0.0)
    app.run(host="0.0.0.0", port=8080)