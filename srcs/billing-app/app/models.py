from app import db


class Order(db.Model):
    __tablename__ = "orders"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(50), nullable=False)
    number_of_items = db.Column(db.Integer, nullable=False)
    total_amount = db.Column(db.Float, nullable=False)