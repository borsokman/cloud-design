from flask import Blueprint, request, jsonify
from app import db
from app.models import Movie

movies_bp = Blueprint("movies", __name__)


@movies_bp.route("/api/movies", methods=["GET"])
def get_movies():
    title = request.args.get("title")
    query = Movie.query
    if title:
        query = query.filter(Movie.title.ilike(f"%{title}%"))
    movies = query.all()
    return jsonify([{"id": m.id, "title": m.title, "description": m.description} for m in movies]), 200


@movies_bp.route("/api/movies", methods=["POST"])
def add_movie():
    data = request.get_json(silent=True) or {}
    if "title" not in data or not str(data["title"]).strip():
        return jsonify({"error": "title is required"}), 400
    if "description" not in data or not str(data["description"]).strip():
        return jsonify({"error": "description is required"}), 400

    movie = Movie(title=str(data["title"]).strip(), description=str(data["description"]).strip(),)
    db.session.add(movie)
    db.session.commit()
    return jsonify({"id": movie.id, "title": movie.title, "description": movie.description}), 201


@movies_bp.route("/api/movies", methods=["DELETE"])
def delete_all_movies():
    deleted = Movie.query.delete()
    db.session.commit()
    return jsonify({"deleted": deleted}), 200


@movies_bp.route("/api/movies/<int:movie_id>", methods=["GET"])
def get_movie(movie_id):
    movie = db.session.get(Movie, movie_id)
    if not movie:
        return jsonify({"error": "movie not found"}), 404
    return jsonify({"id": movie.id, "title": movie.title, "description": movie.description}), 200


@movies_bp.route("/api/movies/<int:movie_id>", methods=["PUT"])
def update_movie(movie_id):
    movie = db.session.get(Movie, movie_id)
    if not movie:
        return jsonify({"error": "movie not found"}), 404

    data = request.get_json(silent=True) or {}
    if "title" in data:
        if not str(data["title"]).strip():
            return jsonify({"error": "title cannot be empty"}), 400
        movie.title = data["title"].strip()
    if "description" in data:
        if not str(data["description"]).strip():
            return jsonify({"error": "description cannot be empty"}), 400
        movie.description = str(data["description"]).strip()

    db.session.commit()
    return jsonify({"id": movie.id, "title": movie.title, "description": movie.description}), 200


@movies_bp.route("/api/movies/<int:movie_id>", methods=["DELETE"])
def delete_movie(movie_id):
    movie = db.session.get(Movie, movie_id)
    if not movie:
        return jsonify({"error": "movie not found"}), 404

    db.session.delete(movie)
    db.session.commit()
    return jsonify({"deleted": movie_id}), 200