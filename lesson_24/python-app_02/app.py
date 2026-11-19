import os
from flask import Flask, jsonify, request
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from bson.json_util import dumps
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
mongo_uri = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/autoshop')
app.config["MONGO_URI"] = mongo_uri
mongo = PyMongo(app)
db = mongo.db.cars

@app.route('/api/cars', methods=['GET'])
def get_cars():
    cars = list(db.find())
    return dumps(cars)

@app.route('/api/cars', methods=['POST'])
def add_car():
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    result = db.insert_one({
        "brand": data["brand"],
        "model": data["model"],
        "year": data["year"],
        "price": data["price"]
    })
    return jsonify({"id": str(result.inserted_id)}), 201

@app.route('/api/cars/<id>', methods=['PUT'])
def update_car(id):
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    result = db.update_one(
        {"_id": ObjectId(id)},
        {"$set": {
            "brand": data["brand"],
            "model": data["model"],
            "year": data["year"],
            "price": data["price"]
        }}
    )
    if result.modified_count == 0:
        return jsonify({"error": "Car not found"}), 404
    return jsonify({"message": "Car updated"}), 200

@app.route('/api/cars/<id>', methods=['DELETE'])
def delete_car(id):
    result = db.delete_one({"_id": ObjectId(id)})
    if result.deleted_count == 0:
        return jsonify({"error": "Car not found"}), 404
    return jsonify({"message": "Car deleted"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
