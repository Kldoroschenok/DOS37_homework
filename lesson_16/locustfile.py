from locust import HttpUser, task, between, SequentialTaskSet
from random import randint
import string
import random


def random_text(prefix="note", length=24):
    alphabet = string.ascii_letters + string.digits
    suffix = "".join(random.choice(alphabet) for _ in range(length))
    return f"{prefix}-{suffix}"


class DiaryFlow(SequentialTaskSet):
    @task
    def open_home(self):
        with self.client.get("/", name="GET /", catch_response=True) as resp:
            if resp.status_code != 200 or "Личный дневник" not in resp.text:
                resp.failure("Home page is invalid")

    @task
    def get_notes_json(self):
        with self.client.get("/api/notes", name="GET /api/notes", catch_response=True) as resp:
            if resp.status_code != 200:
                resp.failure("API notes endpoint failed")

    @task
    def add_note(self):
        note_text = random_text(length=randint(12, 32))
        with self.client.post(
            "/add",
            data={"text": note_text},
            name="POST /add",
            allow_redirects=False,
            catch_response=True,
        ) as resp:
            if resp.status_code not in (302, 303):
                resp.failure(f"Unexpected status: {resp.status_code}")

    @task
    def open_notes_page(self):
        with self.client.get("/notes", name="GET /notes", catch_response=True) as resp:
            if resp.status_code != 200 or "Все заметки" not in resp.text:
                resp.failure("Notes page is invalid")


class DiaryUser(HttpUser):
    tasks = [DiaryFlow]
    wait_time = between(1, 3)
