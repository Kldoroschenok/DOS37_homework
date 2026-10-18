#!/bin/bash

set -u

APP_DIR="/opt/srv/webapp"
APP_USER="webadmin"
APP_GROUP="webgroup"
SERVICE_NAME="web_server.service"

# Проверка root
if [[ $EUID -ne 0 ]]; then
    echo "Error: run as root (use sudo)" >&2
    exit 1
fi

echo "1. Creating group and user..."
if ! getent group "${APP_GROUP}" >/dev/null; then
    groupadd --system "${APP_GROUP}"
    echo "   Group ${APP_GROUP} created"
fi

if ! id "${APP_USER}" >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin -g "${APP_GROUP}" "${APP_USER}"
    echo "   User ${APP_USER} created"
fi

echo "2. Creating directories..."
mkdir -p "${APP_DIR}/content"
# Создаем симлинк
ln -sfn "${APP_DIR}" "/srv/webapp"

echo "3. Copying files..."
cp web_server.py "${APP_DIR}/"
cp content/index.html "${APP_DIR}/content/"

echo "4. Setting permissions..."
chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"
chmod 755 "${APP_DIR}"
chmod 644 "${APP_DIR}/web_server.py"
chmod 644 "${APP_DIR}/content/index.html"

echo "5. Installing systemd service..."
cp "${SERVICE_NAME}" "/etc/systemd/system/"
chmod 644 "/etc/systemd/system/${SERVICE_NAME}"

echo "6. Starting service..."
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}"

echo "7. Checking availability..."
sleep 2
if curl -s http://127.0.0.1:8000/ | grep -q "Hello, DOS-29-ONL"; then
    echo "Success! Server is running on port 8000."
else
    echo "Error: Server is not responding correctly."
    journalctl -u "${SERVICE_NAME}" -n 10 --no-pager
    exit 1
fi
