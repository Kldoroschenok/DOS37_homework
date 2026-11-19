from flask import Flask
from redis import Redis
import os

app = Flask(__name__)
redis = Redis(host=os.environ.get('REDIS_HOST', 'redis'), port=6379)

@app.route('/')
def hello():
    count = redis.incr('hits')
    return f'Hello World! I have been seen {count} times.\n'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)