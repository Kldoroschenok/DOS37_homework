from flask import Flask, jsonify
import os
import time

app = Flask(__name__)

@app.route('/')
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Nginx Test App</title>
        <link rel="stylesheet" href="/static/style.css">
    </head>
    <body>
        <h1>Welcome to the test app!</h1>
        <p>This is the main page served by Flask via Nginx</p>
        <img src="/static/nginx-logo.png" alt="Nginx Logo" width="200">
        <p>Examples of endpoints:</p>
        <ul>
            <li><a href="/api/data">/api/data</a> - JSON API</li>
            <li><a href="/slow">/slow</a> - Slow request (3s) </li>
            <li><a href="/static/index.html">/static/index.html</a> - Static file </li>
        </ul>
    </body>
    </html>
    """

@app.route('/api/data')
def api_data():
    return jsonify({
        "status": "success",
        "message": "Data from the Flask application",
        "timestamp": time.time(),
        "items": [1, 2, 3, 4, 5]
    })

@app.route('/slow')
def slow_response():
    time.sleep(3) 
    return "This response took 3 seconds!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
