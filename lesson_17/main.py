import os
from contextlib import asynccontextmanager

import psycopg
from fastapi import FastAPI, HTTPException

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/autos",
)

INITIAL_MODELS = [
    ("Tesla Model 3", 45000),
    ("BMW X5", 75000),
    ("Toyota Camry", 35000),
]


def get_conn():
    return psycopg.connect(DATABASE_URL)


def init_db():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS car_models (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    price INTEGER NOT NULL
                )
            """)
            cur.execute("""
                CREATE TABLE IF NOT EXISTS orders (
                    id SERIAL PRIMARY KEY,
                    model_id INTEGER NOT NULL REFERENCES car_models(id),
                    customer_name TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT NOW()
                )
            """)
            cur.execute("SELECT COUNT(*) FROM car_models")
            count = cur.fetchone()[0]
            if count == 0:
                cur.executemany(
                    "INSERT INTO car_models (name, price) VALUES (%s, %s)",
                    INITIAL_MODELS,
                )
        conn.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(lifespan=lifespan)


@app.get("/health")
def health():
    try:
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"db unavailable: {e}")


@app.get("/models")
def list_models():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price FROM car_models ORDER BY id")
            rows = cur.fetchall()
    return [
        {"id": row[0], "name": row[1], "price": row[2]}
        for row in rows
    ]


@app.get("/orders")
def list_orders():
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT o.id, o.customer_name, o.created_at, c.id, c.name, c.price
                FROM orders o
                JOIN car_models c ON c.id = o.model_id
                ORDER BY o.id
            """)
            rows = cur.fetchall()
    return [
        {
            "id": row[0],
            "customer_name": row[1],
            "created_at": row[2].isoformat() if row[2] else None,
            "model": {
                "id": row[3],
                "name": row[4],
                "price": row[5],
            },
        }
        for row in rows
    ]
