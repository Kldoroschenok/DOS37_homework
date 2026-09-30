#!/bin/bash

SERVICE_NAME="http_server.service"
HOST="127.0.0.1"
PORT="8080"
HEALTH_URL="http://${HOST}:${PORT}/health"


check_service() {
	echo "Checking service http_server..."

	if systemctl is-active -q "$SERVICE_NAME"; then
		echo "OK: $SERVICE_NAME is running"
		return 0
	else
		echo "FAIL: "$SERVICE_NAME" is not running"
		return 1
	fi
}

check_port() {
	echo "Checking port $PORT..."

	if (echo > /dev/tcp/$HOST/$PORT) 2>/dev/null; then
		echo "OK: port $PORT is available"
		return 0
	else
		echo "FAIL: port $PORT is not available"
		return 1
	fi	
}

check_health() {
	echo "Checking $HEALTH_URL..."

	response=$(curl -s "$HEALTH_URL")

	if echo "$response" | grep -q '"status": "ok"'; then
		echo "OK: /health returned status ok"
		return 0
	else
		echo "FAIL: /health returned unexpected response"
		echo "Response: $response"
		return 1
	fi	
}

check_service
echo "====================="
check_port
echo "====================="
check_health
