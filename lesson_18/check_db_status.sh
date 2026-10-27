#!/usr/bin/env bash

PRIMARY_HOST="192.168.252.98"
REPLICA_HOST="192.168.252.90"
DB_PORT="5432"
DB_USER="app_user"
DB_NAME="notes"
export PGPASSWORD="app_password"

echo "=== Проверка кластера PostgreSQL ==="

# 1. Проверка Primary (Master)
echo -n "1. Primary ($PRIMARY_HOST): "
if psql -h "$PRIMARY_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT 1;" >/dev/null 2>&1; then
    echo "UP"
else
    echo "DOWN (Error)"
fi

# 2. Проверка Replica (Slave) и статуса recovery
echo -n "2. Replica ($REPLICA_HOST): "
if psql -h "$REPLICA_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT 1;" >/dev/null 2>&1; then
    
    IS_RECOVERY=$(psql -h "$REPLICA_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT pg_is_in_recovery();" | xargs)
    
    if [ "$IS_RECOVERY" = "t" ]; then
        echo "UP (in recovery / read-only)"
    else
        echo "UP (WARNING: not in recovery mode)"
    fi
else
    echo "DOWN (Connection failed)"
fi

# 3. Проверка лага репликации (насколько отстает Slave от Master)
echo -n "3. Replication status (on Master): "
REPL_STATE=$(sudo -u postgres psql -t -c "SELECT state FROM pg_stat_replication;" | xargs)

if [ "$REPL_STATE" = "streaming" ]; then
    echo "STREAMING (Working)"
elif [ -z "$REPL_STATE" ]; then
    echo "FAILED (No connected replicas)"
else
    echo "STATE: $REPL_STATE"
fi

echo "===================================="
