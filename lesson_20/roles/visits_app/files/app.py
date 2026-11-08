from flask import Flask, jsonify
import psycopg2
import redis
import os

app = Flask(__name__)

# Подключение к PostgreSQL
conn = psycopg2.connect(
    dbname=os.getenv('POSTGRES_DB'),
    user=os.getenv('POSTGRES_USER'),
    password=os.getenv('POSTGRES_PASSWORD'),
    host=os.getenv('POSTGRES_HOST')
)

# Подключение к Redis
cache = redis.Redis(host=os.getenv('REDIS_HOST'), port=6379, decode_responses=True)

@app.route('/visits')
def get_visits():
    # Проверка кэша
    cached_visits = cache.get('visits')
    if cached_visits:
        return jsonify(visits=int(cached_visits), source='cache')
    
    # Запрос к БД
    with conn.cursor() as cur:
        cur.execute("INSERT INTO visits DEFAULT VALUES RETURNING id;")
        visits = cur.execute("SELECT COUNT(*) FROM visits;")
        conn.commit()
        count = cur.fetchone()[0]
        cache.set('visits', count, ex=30)  # Кэш на 30 сек
        return jsonify(visits=count, source='database')

if __name__ == '__main__':
    app.run(host='0.0.0.0')