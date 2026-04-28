#!/bin/bash
# =============================================================================
# docker-entrypoint-centos.sh
# Entrypoint personalizado para contenedores CentOS con PostgreSQL 16 + Citus
# Inicializa la base de datos y arranca PostgreSQL sin systemd.
# =============================================================================

set -e

# Variables de entorno con valores por defecto
DB_USER="${POSTGRES_USER:-admin}"
DB_PASSWORD="${POSTGRES_PASSWORD:-admin}"
DB_NAME="${POSTGRES_DB:-historia_clinica}"
PGDATA="${PGDATA:-/var/lib/pgsql/16/data}"

PG_BIN="/usr/pgsql-16/bin"

# --- Inicializar si PGDATA está vacío ---
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "=== Inicializando base de datos PostgreSQL 16 ==="
    "$PG_BIN/initdb" -D "$PGDATA" --auth-host=trust --auth-local=trust

    # --- Configurar postgresql.conf ---
    cat >> "$PGDATA/postgresql.conf" <<EOF

# === Configuración Citus ===
shared_preload_libraries = 'citus'
listen_addresses = '*'
wal_level = logical
max_connections = 100
EOF

    # --- Configurar pg_hba.conf para permitir conexiones de la red Docker ---
    cat > "$PGDATA/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               trust
EOF

    # --- Arrancar PostgreSQL temporalmente para crear usuario y BD ---
    "$PG_BIN/pg_ctl" -D "$PGDATA" -w start -o "-p 5432"

    # Crear usuario si no es el default 'postgres'
    if [ "$DB_USER" != "postgres" ]; then
        "$PG_BIN/psql" -U postgres -c "CREATE USER $DB_USER WITH SUPERUSER PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
    fi

    # Crear base de datos
    "$PG_BIN/psql" -U postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true

    # Crear extensión Citus en la BD
    "$PG_BIN/psql" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS citus;" 2>/dev/null || true

    # Detener PostgreSQL temporal
    "$PG_BIN/pg_ctl" -D "$PGDATA" -w stop

    echo "=== Inicialización completada ==="
fi

# --- Arrancar PostgreSQL en foreground ---
echo "=== Arrancando PostgreSQL 16 + Citus ==="
exec "$PG_BIN/postgres" -D "$PGDATA" -p 5432
