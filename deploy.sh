#!/bin/bash

set -u

APP_NAME="http_server"
APP_DIR="/opt/http_server"
APP_USER="web-user"
SERVICE_NAME="http_server.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
LOG_FILE="/var/log/http-server-deploy.log"
HEALTH_URL="http://127.0.0.1:8080/health"

# Директория, где лежит сам скрипт, так же http_server.py и unit-file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Проверяем на запуск через sudo
if [[ $EUID -ne 0 ]]; then
     echo 'ERROR: use "sudo ..."' >&2
     exit 1
fi

# Создание LOG_file
touch "${LOG_FILE}"
chmod 640 "${LOG_FILE}"

log() {
   local level="$1"; shift
   local data_time
   data_time="$(date '+%Y-%m-%d %H:%M:%S')"
   echo "[${data_time}] [${level}] $*" | tee -a "${LOG_FILE}"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARNING" "$@"; }
log_error() { log "ERROR" "$@"; }

fail() {
    log_error "$*"
    log_error "deployment stopped"
    exit 1
}

# Проверка user - web-user
log_info "---start of deployment ${APP_NAME}---"
log_info "1. Check user: ${APP_USER}"

if id "${APP_USER}" >/dev/null 2>&1; then
   log_info "User ${APP_USER} - exists (uid=$(id -u "${APP_USER}"))"
else
   log_info "User ${APP_USER} - not found. Created..."
   if useradd -m -s /bin/bash "${APP_USER}"; then
       log_info "User ${APP_USER} created"
   else
       fail "Failed to create a user ${APP_USER}"
   fi
fi

# Проверка директории

log_info "2. Check directory ${APP_DIR}"

if [[ -d "$APP_DIR" ]]; then
	log_info "Directory ${APP_DIR} - exists"
else
	log_info "Directory ${APP_DIR} - not found. Created..."
	if mkdir -p "${APP_DIR}"; then
		log_info "Directory ${APP_DIR} created"
	else
		fail "Failed to create a directory ${APP_DIR}"
	fi
fi

# Проверка наличия исходников для установки

log_info "3. Checking the source files in ${SCRIPT_DIR}"

if [[ ! -f "${SCRIPT_DIR}/http_server.py" ]]; then
	fail "File not found ${SCRIPT_DIR}/http_server.py"
fi

if [[ ! -f "${SCRIPT_DIR}/http_server.service" ]]; then
	fail "File not found ${SCRIPT_DIR}/http_server.service"
fi

log_info "Source files - found"

# Копирование приложения

log_info "4. Copy http_server.py in ${APP_DIR}"

if cp "${SCRIPT_DIR}/http_server.py" "$APP_DIR/http_server.py"; then
	log_info "File http_server.py - copied"
else
	fail "Failed to copy http_server.py"
fi

# Задаем права на файл

log_info "5. Settings rights - ${APP_DIR}"

chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"
chmod 755 "${APP_DIR}"
chmod 644 "${APP_DIR}/http_server.py"
log_info "Rights are set:${APP_USER}:${APP_USER}, directory 755, file 644"

# Unit-файл

log_info "6. Copy unit-file ${SERVICE_PATH}"

if cp "${SCRIPT_DIR}/http_server.service" "{SERVICE_PATH}"; then
	chmod 644 "${SERVICE_PATH}"
	log_info "Unit-file - copied"
else
	fail "Failed to copy unit-file"
fi

# Перезагружаем systemd и запускаем сервис
log_info "7. daemon-reload and start service"

if ! systemctl daemon-reload; then
	fail "systemctl daemon-reload - failed"
fi
log_info "daemon-reload - finish"

systemctl enable "${SERVICE_NAME}" >/dev/null 2>&1
log_info "Service ${SERVICE_NAME} add autorun"

if systemctl restart "${SERVICE_NAME}"; then
	log_info "${SERVICE_NAME} restarted"
else
	fail "Failed restart ${SERVICE_NAME}"
fi

# Ждем запуска сервиса

log_info "8. Waiting for service to be ready (10 second)"
sleep 10
log_info "Service health check"

if ! curl -s --max-time 2 "${HEALTH_URL}" >/dev/null 2>&1; then
	log_error "Service unavailable"
	log_error "Tail of log (20)"
	journalctl -u "${SERVICE_NAME}" -n 20 --no-pager | tee -a "${LOG_FILE}" >&2
	fail "Health check - failed"
fi

log_info "Service available"

# Проверяем /health

log_info "9. Check ${HEALTH_URL}"

response="$(curl -s --max-time 5 "${HEALTH_URL}")"
log_info "Response ${response}"

if echo "${response}" | grep -q '"status": "ok"'; then
	log_info "Health-check OK"
else
	fail "Health_check not OK"
fi

# Вывод итоговой информации

log_info "---${APP_NAME} deployment successful---"
echo
echo "Service:   systemctl status ${SERVICE_NAME}"
echo "Journal:   journalctl -u ${SERVICE_NAME} -f"
echo "Log file:  tail -f ${LOG_FILE}"
echo "Check:     curl ${HEALTH_URL}"
exit 0
