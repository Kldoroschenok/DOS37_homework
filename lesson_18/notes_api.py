import os
import time
from contextlib import contextmanager

import psycopg2
from flask import Flask, jsonify, request

PRIMARY_DSN = os.getenv(
    "PRIMARY_DSN",
    "host=127.0.0.1 port=5432 dbname=notes user=app_user password=app_password",
)

REPLICA_DSN = os.getenv(
    "REPLICA_DSN",
    "host=127.0.0.1 port=5433 dbname=notes user=app_user password=app_password",
)

app = Flask(__name__)


@contextmanager
def get_connection(dsn: str):
    conn = psycopg2.connect(dsn, connect_timeout=3)
    try:
        yield conn
    finally:
        conn.close()


def init_schema():
    with get_connection(PRIMARY_DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS notes (
                    id BIGSERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
        conn.commit()


@app.get("/health")
def health():
    result = {
        "primary": "down",
        "replica": "down",
        "replica_in_recovery": None,
    }

    try:
        with get_connection(PRIMARY_DSN) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        result["primary"] = "up"
    except psycopg2.Error:
        pass

    try:
        with get_connection(REPLICA_DSN) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT pg_is_in_recovery()")
                result["replica_in_recovery"] = cur.fetchone()[0]
        result["replica"] = "up"
    except psycopg2.Error:
        pass

    status = 200 if result["primary"] == "up" else 503
    return jsonify(result), status


@app.post("/notes")
def create_note():
    data = request.get_json(silent=True) or {}

    title = (data.get("title") or "").strip()
    body = (data.get("body") or "").strip()

    if not title or not body:
        return jsonify({"error": "title and body are required"}), 400

    try:
        with get_connection(PRIMARY_DSN) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO notes (title, body)
                    VALUES (%s, %s)
                    RETURNING id, title, body, created_at
                    """,
                    (title, body),
                )
                row = cur.fetchone()
            conn.commit()
    except psycopg2.Error as exc:
        return jsonify({"error": "primary write failed", "details": str(exc)}), 503

    return jsonify(
        {
            "id": row[0],
            "title": row[1],
            "body": row[2],
            "created_at": row[3].isoformat(),
        }
    ), 201


@app.get("/notes")
def list_notes():
    wait_for_replica = request.args.get("wait") == "true"
    target_id = request.args.get("after_id", type=int)

    try:
        if wait_for_replica and target_id is not None:
            wait_until_replica_has_id(target_id)

        with get_connection(REPLICA_DSN) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT id, title, body, created_at
                    FROM notes
                    ORDER BY id DESC
                    LIMIT 50
                    """
                )
                rows = cur.fetchall()
    except psycopg2.Error as exc:
        return jsonify({"error": "replica read failed", "details": str(exc)}), 503

    return jsonify(
        [
            {
                "id": row[0],
                "title": row[1],
                "body": row[2],
                "created_at": row[3].isoformat(),
            }
            for row in rows
        ]
    )


def wait_until_replica_has_id(note_id: int, timeout: float = 5.0):
    deadline = time.time() + timeout

    while time.time() < deadline:
        try:
            with get_connection(REPLICA_DSN) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1 FROM notes WHERE id = %s", (note_id,))
                    if cur.fetchone():
                        return
        except psycopg2.Error:
            pass

        time.sleep(0.1)

    raise TimeoutError(f"replica did not receive note {note_id} within {timeout}s")


if __name__ == "__main__":
    init_schema()
    app.run(host="0.0.0.0", port=8000)
