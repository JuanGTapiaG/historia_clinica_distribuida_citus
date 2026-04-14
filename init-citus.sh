#!/bin/bash
# =============================================================================
# init-citus.sh
# Script de inicialización para el cluster Citus.
# Registra los workers, crea el esquema distribuido e inserta datos de ejemplo.
# =============================================================================

set -e

COORDINATOR="citus_coordinator"
DB_USER="admin"
DB_NAME="historia_clinica"

echo "============================================="
echo " Inicializando Cluster Citus"
echo "============================================="

# --- Paso 1: Esperar a que el coordinador esté listo ---
echo ""
echo "[1/5] Esperando a que el coordinador esté listo..."
until docker exec "$COORDINATOR" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; do
  echo "  Coordinador no disponible, reintentando en 3s..."
  sleep 3
done
echo "  ✔ Coordinador listo."

# --- Paso 2: Esperar a que los workers estén listos ---
echo ""
echo "[2/5] Esperando a que los workers estén listos..."
for WORKER in citus_worker1 citus_worker2; do
  until docker exec "$WORKER" pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; do
    echo "  $WORKER no disponible, reintentando en 3s..."
    sleep 3
  done
  echo "  ✔ $WORKER listo."
done

# --- Paso 3: Crear extensión Citus y registrar workers ---
echo ""
echo "[3/5] Creando extensión Citus y registrando workers..."
docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS citus;"
docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT citus_add_node('citus_worker1', 5432);"
docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT citus_add_node('citus_worker2', 5432);"
echo "  ✔ Workers registrados."

# Verificar workers activos
echo ""
echo "  Workers activos:"
docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM citus_get_active_worker_nodes();"

# --- Paso 4: Ejecutar esquema distribuido ---
echo ""
echo "[4/5] Creando esquema distribuido..."
docker exec -i "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" < /mnt/schema_citus.sql 2>&1 || \
  docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -f /mnt/schema_citus.sql
echo "  ✔ Esquema creado."

# --- Paso 5: Insertar datos de ejemplo ---
echo ""
echo "[5/5] Insertando datos de ejemplo..."
docker exec -i "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" < /mnt/insert_datos.sql 2>&1 || \
  docker exec "$COORDINATOR" psql -U "$DB_USER" -d "$DB_NAME" -f /mnt/insert_datos.sql
echo "  ✔ Datos insertados."

# --- Resumen ---
echo ""
echo "============================================="
echo " ✔ Cluster Citus inicializado correctamente"
echo "============================================="
echo ""
echo "Puedes conectarte al coordinador con:"
echo "  docker exec -it $COORDINATOR psql -U $DB_USER -d $DB_NAME"
echo ""
echo "Consultas de validación:"
echo "  SELECT * FROM citus_get_active_worker_nodes();"
echo "  SELECT * FROM citus_tables;"
echo "  SELECT * FROM usuario WHERE documento_id > 0;"
echo ""
