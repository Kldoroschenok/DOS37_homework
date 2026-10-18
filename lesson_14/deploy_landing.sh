#!/bin/bash

set -u

# Конфигурация
APP_NAME="web_app"
SERVICE_USER="www-data"
REPO_URL="https://gitlab.com/dos-26/cmdb/frontend.git"
REPO_BRANCH="main"

WEB_ROOT="/var/www/html/${APP_NAME}"
NGINX_AVAILABLE="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"
NGINX_DEFAULT_ENABLED="/etc/nginx/sites-enabled/default"

LOG_FILE="/var/log/deploy_landing.log"
TEMP_DIR=""

# Проверка root
if [[ $EUID -ne 0 ]]; then
    echo 'Error: the script must be run as root (use sudo)' >&2
    exit 1
fi

# Логирование
touch "${LOG_FILE}"
chmod 640 "${LOG_FILE}"

log() {
    local level="$1"; shift
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${ts}] [${level}] $*" | tee -a "${LOG_FILE}"
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }

fail() {
    log_error "$*"
    log_error "deployment terminatd."
    exit 1
}

# Очистка временной директории при выходе
cleanup() {
    if [[ -n "${TEMP_DIR}" ]] && [[ -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
        log_info "TEMP directory deleted: ${TEMP_DIR}"
    fi
}
trap cleanup EXIT

# 1. Проверка зависимостей
log_info "=== Start deployment ${APP_NAME} ==="
log_info "1. Checking dependencies..."

for tool in nginx git curl; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        fail "utility not found: ${tool}"
    fi
    log_info "Found: ${tool} ($(command -v "${tool}"))"
done

# 2. Проверка пользователя www-data
log_info "2. Checking user ${SERVICE_USER}"

if id "${SERVICE_USER}" >/dev/null 2>&1; then
    log_info "User ${SERVICE_USER} exists (uid=$(id -u "${SERVICE_USER}"))"
else
    fail "User ${SERVICE_USER} not found"
fi

# 3. Подготовка директории web_app
log_info "3. Directory preparation ${WEB_ROOT}"

if [[ -d "${WEB_ROOT}" ]]; then
    log_info "Directory ${WEB_ROOT} exists, clearing contents..."
    rm -rf "${WEB_ROOT:?}/"* "${WEB_ROOT:?}/".[!.]* 2>/dev/null || true
else
    log_info "Directory ${WEB_ROOT} not found, creating"
    mkdir -p "${WEB_ROOT}" || fail "Failed to create ${WEB_ROOT}"
fi

log_info "Directory ${WEB_ROOT} created"

# 4. Клонирование репозитория
log_info "4. Cloning repository ${REPO_URL}"

TEMP_DIR="$(mktemp -d)"
log_info "TEMP directory: ${TEMP_DIR}"

if git clone --depth 1 --branch "${REPO_BRANCH}" "${REPO_URL}" "${TEMP_DIR}" >> "${LOG_FILE}" 2>&1; then
    log_info "Repository cloned (branch ${REPO_BRANCH})"
else
    fail "Failed to clone ${REPO_URL}"
fi

if [[ ! -d "${TEMP_DIR}/public" ]]; then
    fail "Directory public/ not found in repository" 
fi
log_info "Directory public/ found in repository"

# 5. Копирование содержимого public/
log_info "5. Copying landing page files to ${WEB_ROOT}"

if cp -r "${TEMP_DIR}/public/." "${WEB_ROOT}/"; then
    log_info "Files copied"
else
    fail "Failed to copy files from public/"
fi

if [[ ! -f "${WEB_ROOT}/index.html" ]]; then
    fail "File ${WEB_ROOT}/index.html not found after copyning"
fi
log_info "File index.html in place"

# 6. Установка прав
log_info "6. Setting permissions for ${WEB_ROOT}"

chown -R "${SERVICE_USER}:${SERVICE_USER}" "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

log_info "Permissions set: ${SERVICE_USER}:${SERVICE_USER}, 755/644"

# 7. Создание конфига Nginx
log_info "7. Creating config Nginx ${NGINX_AVAILABLE}"

cat > "${NGINX_AVAILABLE}" <<NGINX_EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root ${WEB_ROOT};
    index index.html;

    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log  /var/log/nginx/${APP_NAME}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
NGINX_EOF

log_info "Config Nginx created"

# 8. Активация конфига
log_info "8. Activating configuration Nginx"

if ln -sf "${NGINX_AVAILABLE}" "${NGINX_ENABLED}"; then
    log_info "Symlink created: ${NGINX_ENABLED}"
else
    fail "Failed to create symlink ${NGINX_ENABLED}"
fi

if [[ -L "${NGINX_DEFAULT_ENABLED}" ]] || [[ -f "${NGINX_DEFAULT_ENABLED}" ]]; then
    if rm -f "${NGINX_DEFAULT_ENABLED}"; then
        log_info "Default config remove: ${NGINX_DEFAULT_ENABLED}"
    else
        log_warn "Failed to remove ${NGINX_DEFAULT_ENABLED}"
    fi
fi

# 9. Проверка и перезагрузка Nginx
log_info "9. Checking configuration and restarting Nginx"

if nginx -t >> "${LOG_FILE}" 2>&1; then
    log_info "Config Nginx valid"
else
    log_error "Config Nginx invalid"
    nginx -t 2>&1 | tee -a "${LOG_FILE}" >&2
    fail "nginx -t failed"
fi

if systemctl reload nginx; then
    log_info "Nginx reloaded"
else
    fail "Failed to reload Nginx"
fi

# 10. Проверка доступности
log_info "10. Checking landing availability"

sleep 1

http_code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost/ || echo '000')"
log_info "HTTP-code from http://localhost/: ${http_code}"

if [[ "${http_code}" == "200" ]]; then
    log_info "Landing available (HTTP 200)"
else
    log_error "Landing returned code ${http_code}"
    fail "Availability check failed"
fi

body="$(curl -s http://localhost/ | head -20)"
if echo "${body}" | grep -q "CMDB System"; then
    log_info "Marker found is response 'CMDB System' — correct marker returned"
else
    log_warn "Marker 'CMDB System' not found in response"
fi

#  Готово
log_info "=== Deployment ${APP_NAME} completed successfully ==="
echo
echo "Landing available: http://localhost/"
echo "Directory:       ${WEB_ROOT}"
echo "Config Nginx:     ${NGINX_AVAILABLE}"
echo "Deployment log:       ${LOG_FILE}"
echo "Log Nginx:       /var/log/nginx/${APP_NAME}_access.log"
echo "                  /var/log/nginx/${APP_NAME}_error.log"
exit 0
