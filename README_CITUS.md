
# Historia Clínica Distribuida con PostgreSQL + Citus

Este laboratorio implementa una **base de datos distribuida real** usando PostgreSQL con la extensión **Citus**,
permitiendo fragmentar automáticamente los datos y distribuir las consultas de forma transparente.

---

## Fundamento Teórico — Bases de Datos Distribuidas

Un **sistema de bases de datos distribuidas** es un conjunto de múltiples bases de datos lógicamente relacionadas,
dispersas en diferentes nodos físicos o ubicaciones geográficas y conectadas por una red. Aunque los datos están
distribuidos, el sistema se presenta al usuario como una **sola unidad unificada y coherente**.

### Características Clave

| Característica | Descripción |
|---|---|
| **Distribución** | Los nodos pueden ser servidores separados geográficamente o máquinas virtuales. |
| **Autonomía Local** | Cada sitio puede procesar datos de manera local e independiente. |
| **Transparencia** | El usuario no necesita saber dónde residen los datos para acceder a ellos. |

### Ventajas

- **Escalabilidad**: Mayor facilidad para escalar horizontalmente la infraestructura.
- **Tolerancia a fallos**: Si un nodo falla, el sistema sigue funcionando mediante copias.
- **Rendimiento mejorado**: Menor latencia al acceder a datos locales.

### Tipos

- **Homogéneas**: Todos los nodos utilizan el mismo SGBD.
- **Heterogéneas**: Los nodos pueden utilizar diferentes SGBD, dificultando la integración.

### Desventajas

- Aumento en la complejidad del diseño.
- Mayor dificultad en la seguridad y control de red.
- Consistencia eventual en algunos sistemas.

### Ejemplos Comunes

| Tipo | Ejemplos |
|---|---|
| **NoSQL** | MongoDB, Cassandra, DynamoDB |
| **Relacional (con soporte distribuido)** | Oracle, PostgreSQL + Citus, Microsoft SQL Server |

### ¿Qué es Citus?

**Citus** es la extensión más conocida para convertir PostgreSQL en una base de datos distribuida mediante
**sharding** (fragmentación) de datos en múltiples nodos, permitiendo el escalado horizontal.
Es ideal para aplicaciones SaaS multiinquilino y análisis de datos en tiempo real.

---

## Arquitectura del Laboratorio

```
                    ┌─────────────────────────────┐
                    │      COORDINADOR (Citus)     │
                    │   Puerto: 5432               │
                    │   Recibe todas las consultas  │
                    │   Distribuye a los workers    │
                    └─────────┬───────┬────────────┘
                              │       │
                 ┌────────────┘       └────────────┐
                 │                                  │
        ┌────────▼────────┐               ┌────────▼────────┐
        │   WORKER 1      │               │   WORKER 2      │
        │   Shards pares  │               │   Shards impares│
        │   Almacena      │               │   Almacena      │
        │   fragmentos    │               │   fragmentos    │
        └─────────────────┘               └─────────────────┘
```

**Distribución de tablas:**
- `usuario`, `atencion`, `tecnologia_salud`, `diagnostico`, `egreso` → **distribuidas** por `documento_id`
- `profesional_salud` → **replicada** (copia completa en cada worker)

---

## Requisitos

- Docker
- Docker Compose
- Bash (para el script de inicialización)

---

## Instrucciones

### 1. Clonar el repositorio

```bash
git clone https://github.com/jaiderreyes/historia_clinica_distribuida_citus.git
cd historia_clinica_distribuida_citus
```

### 2. Levantar los servicios

```bash
docker-compose -f docker-compose-citus.yml up -d
```

Esto levanta 3 contenedores:
- `citus_coordinator` (puerto 5432)
- `citus_worker1`
- `citus_worker2`

### 3. Inicializar el cluster

Ejecuta el script de inicialización que registra los workers, crea el esquema y carga los datos:

```bash
bash init-citus.sh
```

El script realiza automáticamente:
1. Espera a que todos los nodos estén disponibles.
2. Crea la extensión Citus en el coordinador.
3. Registra los 2 workers.
4. Ejecuta `schema_citus.sql` (crea tablas distribuidas).
5. Ejecuta `insert_datos.sql` (carga datos de ejemplo).

### 4. (Alternativa) Inicialización manual

Si prefiere ejecutar los pasos manualmente:

```bash
# Crear extensión Citus
docker exec -it citus_coordinator psql -U admin -d historia_clinica -c "CREATE EXTENSION IF NOT EXISTS citus;"

# Registrar workers
docker exec -it citus_coordinator psql -U admin -d historia_clinica -c "SELECT citus_add_node('citus_worker1', 5432);"
docker exec -it citus_coordinator psql -U admin -d historia_clinica -c "SELECT citus_add_node('citus_worker2', 5432);"

# Crear esquema
docker exec -i citus_coordinator psql -U admin -d historia_clinica < schema_citus.sql

# Insertar datos
docker exec -i citus_coordinator psql -U admin -d historia_clinica < insert_datos.sql
```

---

## Validación

### Verificar workers activos

```sql
SELECT * FROM citus_get_active_worker_nodes();
```

### Ver tablas distribuidas

```sql
SELECT * FROM citus_tables;
```

### Consulta simple distribuida

```sql
SELECT * FROM usuario WHERE documento_id > 0;
```

### Consulta con JOINs distribuidos

```sql
SELECT
    u.nombre_completo,
    u.documento_id,
    a.entidad_salud,
    a.causa_atencion,
    d.diagnostico_ingreso,
    d.diagnostico_egreso
FROM usuario u
JOIN atencion a ON u.documento_id = a.documento_id
JOIN diagnostico d ON u.documento_id = d.documento_id AND a.atencion_id = d.atencion_id
ORDER BY a.fecha_ingreso;
```

### Consulta con tabla replicada

```sql
SELECT
    u.nombre_completo,
    ts.descripcion_medicamento,
    ts.dosis,
    ts.frecuencia,
    ps.nombre AS profesional,
    ps.especialidad
FROM usuario u
JOIN tecnologia_salud ts ON u.documento_id = ts.documento_id
JOIN profesional_salud ps ON ts.id_personal_salud = ps.id_personal_salud
ORDER BY u.nombre_completo;
```

### Verificar distribución de shards

```sql
SELECT
    logicalrelid AS tabla,
    shardid,
    nodename AS nodo,
    nodeport AS puerto
FROM citus_shards
ORDER BY logicalrelid, shardid;
```

---

## Archivos

```
.
├── docker-compose-citus.yml   # Orquestación de contenedores (coordinador + 2 workers)
├── init-citus.sh              # Script de inicialización automática del cluster
├── schema_citus.sql           # Esquema DDL con tablas distribuidas y replicadas
├── insert_datos.sql           # Datos de ejemplo para las 6 tablas
├── README_CITUS.md            # Este archivo
```

---

## Detener y limpiar

```bash
# Detener contenedores
docker-compose -f docker-compose-citus.yml down

# Detener y eliminar volúmenes (borra todos los datos)
docker-compose -f docker-compose-citus.yml down -v
```

---

## Autor

Jaider Reyes Herazo — Ingeniero Experto SRE
