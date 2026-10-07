#!/bin/bash

set -u

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 M N" >&2
	exit 1
fi

M="$1"
N="$2"

# Проверка, что цисла целые

if ! [[ "${M}" =~ ^[0-9]+$ ]]; then
	echo "Error: M must be an integer (got '${M}')" >&2
	exit 1
fi

if ! [[ "${N}" =~ ^[0-9]+$ ]]; then
	echo "Error: N must be an integer (got '${N}')" >&2
	exit 1
fi

# Проверка возможного диапазона

if [[ ${M} -lt 1 ]] || [[ ${M} -gt 65535 ]]; then
	echo "Error: M must be in range 1..65535 (got ${M})" >&2
	exit 1
fi

if [[ ${N} -lt 1 ]] || [[ ${N} -gt 65535 ]]; then
	echo "Error: N must be in range 1..65535 (got ${N})" >&2
	exit 1
fi

if [[ ${M} -gt ${N} ]]; then
	echo "Error: M must be <= N (got M=${M}, N=${N})" >&2
	exit 1
fi

# Функция проверки, свободен ли порт

is_port_free() {
	local port="$1"

if command -v ss >/dev/null 2>&1; then
	if ss -ltnH 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$"; then
		return 1
	fi
fi
}

# Поиск первого свободного порта

port="${M}"
while [[ ${port} -le ${N} ]]; do
	if is_port_free "${port}"; then
		echo "${port}"
		exit 0
	fi
	port=$((port + 1))
done

# Порт не найден

echo "No free port in range ${M}-${N}" >&2
exit 2
