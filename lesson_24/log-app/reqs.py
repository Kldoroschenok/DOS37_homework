#!/usr/bin/python3
import random
import time
import requests

MAIN_URL = "http://127.0.0.1"

PORTS = [8081, 8082]
URLS = ["/auth", "/pay", "/login", "/logout", "/refund", "/lk"]

for i in range(1, 25):
    port = random.choice(PORTS)
    url = random.choice(URLS)
    x = requests.get(f"{MAIN_URL}:{port}{url}")
    print(f" Request on {port} url {url} get response code {x.status_code}")
    time.sleep(2)
