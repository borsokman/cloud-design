from flask import Flask

def create_app():
    app = Flask(__name__)
    from app.routes import gateway_bp
    app.register_blueprint(gateway_bp)
    return app