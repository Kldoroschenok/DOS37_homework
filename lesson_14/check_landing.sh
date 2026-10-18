#!/bin/bash

set -u

HOST="127.0.0.1"
PORT="80"
BASE_URL="http://${HOST}:${PORT}"
LANDING_MARKER="CMDB System"

SERVICE_NAME="nginx"
LOG_FILE="/var/log/check_landing.log"

# Логирование
if ! touch "${LOG_FILE}" 2>/dev/null; then
	LOG_FILE="${HOME}/check_landing.log"
	touch "${LOG_FILE}"
fi

log() {
	local level="$1"; shift
	local ts
	ts="$(date '+%Y-%m-%d %H:%M:%S')"
	echo "[${ts}] [${level}] $*" | tee -a "${LOG_FILE}"
}

fail_count=0

ok() { log "OK" "$*"; }
err() { log "FAIL" "$*"; fail_count=$((fail_count +1)); }
info() { log "INFO" "$*"; }

# 1. Проверка systemd-сервиса Nginx

echo "1. Checking service ${SERVICE_NAME}"

if systemctl is-active --quiet "${SERVICE_NAME}"; then
	state="$(systemctl is-active "${SERVICE_NAME}")"
	ok "Service ${SERVICE_NAME} active (state=${state})"
else
	state="$(systemctl is-active "${SERVICE_NAME}" 2>/dev/null || true)"
	if [[ -z "${state}" ]]; then
		state="unknown"
	fi
	err "Service ${SERVICE_NAME} inactive (state=${state})"
	info "systemctl status ${SERVICE_NAME}"
fi

#  Проверка порта

echo
echo "2. Check port ${HOST}:${PORT}"

port_open=0
if command -v ss >/dev/null 2>&1; then
	if ss -ltnH 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${PORT}$"; then
		port_open=1
	fi
fi

if [[ ${port_open} -eq 0 ]]; then
	if (exec 3<>"/dev/tcp/${HOST}/${PORT}") 2>/dev/null; then
		exec 3>&- 3<&-
		port_open=1
	fi
fi

if [[ ${port_open} -eq 1 ]]; then
	ok "Port ${PORT} available"
else
	err "Port ${PORT} unavailable"
fi

 # Проверка главной страницы

echo
echo "3. Check ${BASE_URL}"

http_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${BASE_URL}/" 2>/dev/null)"

if [[ "${http_code}" == "200" ]]; then
    ok "GET / → HTTP ${http_code}"
else
    err "GET / → HTTP ${http_code} (expected 200)"
fi 

body="$(curl -s --max-time 5 "${BASE_URL}/" || true)"

if [[ -n "${body}" ]] && echo "${body}" | grep -q "${LANDING_MARKER}"; then
    ok "Marker '${LANDING_MARKER}' found in response"
else
    err "Marker '${LANDING_MARKER}' not found in response"
    info "Another page may be served instead of CMDB landing"
fi

# Проверка статических файлов

echo
echo "4. Checking static files"

for path in /style.css /script.js; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${BASE_URL}${path}" 2>/dev/null)"
    if [[ "${code}" == "200" ]]; then
        ok "GET ${path} → HTTP ${code}"
    else
        err "GET ${path} → HTTP ${code} (expected 200)"
    fi
done

# Итог
echo
if [[ ${fail_count} -eq 0 ]]; then
    info "All checks passed successfully"
    echo "All checks passed successfully"
    exit 0
else
    info "Problems found: ${fail_count}"
    echo "Problems detected — see output above (${fail_count})."
    exit 1
fi
