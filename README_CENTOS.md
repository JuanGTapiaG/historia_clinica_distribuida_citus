<p align="center">
  <img src="https://img.shields.io/badge/CentOS_Stream_9-262577?style=for-the-badge&logo=centos&logoColor=white" alt="CentOS"/>
  <img src="https://img.shields.io/badge/PostgreSQL_16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Citus_16-1A1A2E?style=for-the-badge&logo=postgresql&logoColor=00D4AA" alt="Citus"/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"/>
</p>

# 🏥 Historia Clínica Distribuida — Variante CentOS Stream 9

> Despliegue del sistema de historia clínica distribuida usando contenedores **CentOS Stream 9** personalizados con PostgreSQL 16 + Citus instalados manualmente desde repositorios RPM, sin utilizar la imagen precompilada `citusdata/citus`.

---

## 📋 Tabla de Contenidos

- [¿Por qué CentOS?](#-por-qué-centos)
- [Diferencias vs. Imagen Precompilada](#-diferencias-vs-imagen-precompilada)
- [Arquitectura](#-arquitectura)
- [Qué hace el Dockerfile](#-qué-hace-el-dockerfile)
- [Estructura de Archivos CentOS](#-estructura-de-archivos-centos)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Despliegue](#-instalación-y-despliegue)
- [Consultas de Validación](#-consultas-de-validación)
- [Detener y Limpiar](#-detener-y-limpiar)
- [Resolución de Problemas](#-resolución-de-problemas)
- [Autor](#-autor)

---

## 🤔 ¿Por qué CentOS?

Este despliegue alternativo demuestra cómo instalar y configurar PostgreSQL + Citus **desde cero** en un sistema operativo empresarial, simulando un entorno de producción real:

- 🔧 **Control total** sobre el sistema operativo y las versiones instaladas.
- 📚 **Valor educativo**: comprender qué ocurre "debajo del capó" de la imagen oficial.
- 🏢 **Escenario real**: muchas organizaciones usan RHEL/CentOS en sus servidores de base de datos.
- 🔒 **Personalización**: habilitar módulos adicionales, configuraciones de seguridad específicas, etc.

---

## ⚖️ Diferencias vs. Imagen Precompilada

| Aspecto | `citusdata/citus` (original) | CentOS Stream 9 (esta variante) |
|---|---|---|
| **Imagen base** | Debian (slim) | CentOS Stream 9 |
| **Instalación** | Precompilada | Manual (PGDG + Citus RPM) |
| **PostgreSQL** | 14 | 16 |
| **Citus** | 11.2 | 16 (última) |
| **Tamaño imagen** | ~350 MB | ~600-800 MB |
| **Entrypoint** | Oficial Docker PostgreSQL | Custom `docker-entrypoint-centos.sh` |
| **Puerto coordinador** | 5436 | 5437 |
| **Gestor de paquetes** | apt | dnf (yum) |
| **Init system** | docker-entrypoint.sh oficial | `pg_ctl` + `initdb` manual |

---

## 🏗️ Arquitectura

```
                     ┌──────────────────────────────────────┐
                     │    COORDINADOR (CentOS Stream 9)      │
                     │    PostgreSQL 16 + Citus              │
                     │    Puerto externo: 5437 → 5432        │
                     │    • Recibe todas las consultas        │
                     │    • Planifica y distribuye queries     │
                     └──────────┬──────────┬─────────────────┘
                                │          │
                   ┌────────────┘          └─────────────┐
                   │                                     │
          ┌────────▼─────────┐              ┌────────────▼────────┐
          │   WORKER 1       │              │   WORKER 2          │
          │   CentOS S9      │              │   CentOS S9         │
          │   PG 16 + Citus  │              │   PG 16 + Citus     │
          │   Puerto: 5432   │              │   Puerto: 5432      │
          └──────────────────┘              └─────────────────────┘
```

Todos los nodos corren sobre **CentOS Stream 9** con PostgreSQL 16 y Citus instalados desde RPMs oficiales.

---

## 🐳 Qué hace el Dockerfile

El `Dockerfile.centos` construye la imagen paso a paso:

```dockerfile
# 1. Imagen base CentOS Stream 9
FROM quay.io/centos/centos:stream9

# 2. Instalar repositorio PGDG (PostgreSQL Global Development Group)
RUN dnf install -y https://download.postgresql.org/.../pgdg-redhat-repo-latest.noarch.rpm
RUN dnf -qy module disable postgresql  # Desactivar módulo PostgreSQL por defecto

# 3. Instalar repositorio Citus
RUN curl -s https://install.citusdata.com/community/rpm.sh | bash

# 4. Instalar PostgreSQL 16 + Citus
RUN dnf install -y postgresql16-server postgresql16-contrib citus_16

# 5. Copiar entrypoint personalizado
COPY docker-entrypoint-centos.sh /usr/local/bin/docker-entrypoint.sh
```

### El Entrypoint Personalizado (`docker-entrypoint-centos.sh`)

Como los contenedores Docker no tienen `systemd`, el entrypoint hace todo manualmente:

1. **`initdb`** — Inicializa el clúster PostgreSQL.
2. **Configura `postgresql.conf`** — Agrega `shared_preload_libraries = 'citus'`, `listen_addresses = '*'`, `wal_level = logical`.
3. **Configura `pg_hba.conf`** — Permite conexiones trust desde cualquier IP (red Docker interna).
4. **Crea usuario y BD** — Crea el usuario `admin` y la base de datos `historia_clinica`.
5. **Arranca PostgreSQL** — Con `pg_ctl` en modo foreground.

---

## 📁 Estructura de Archivos CentOS

```
historia_clinica_distribuida_citus/
│
├── 🐳 Dockerfile.centos               # Imagen CentOS Stream 9 + PG16 + Citus
├── 🔧 docker-entrypoint-centos.sh     # Entrypoint personalizado (initdb + pg_ctl)
├── 📄 docker-compose-centos.yml       # Orquestación: 1 coordinador + 2 workers
├── 🔧 init-centos.sh                  # Script para inicializar el clúster
│
├── 🗃️ schema_citus.sql                # Esquema DDL (compartido con variante original)
├── 📊 insert_datos.sql                # Datos de ejemplo (compartido con variante original)
└── 📖 README_CENTOS.md                # Este archivo
```

---

## ✅ Requisitos Previos

| Herramienta | Versión mínima | Descripción |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | 20.10+ | Motor de contenedores |
| [Docker Compose](https://docs.docker.com/compose/install/) | 2.0+ | Orquestación de contenedores |
| Bash | 4.0+ | Shell para scripts de inicialización |
| Conexión a Internet | — | Para descargar paquetes RPM durante el build |

> ⚠️ **Nota**: El primer build descarga ~200 MB de paquetes RPM. Builds posteriores usan la caché de Docker.

---

## 🚀 Instalación y Despliegue

### 1. Clonar el repositorio

```bash
git clone https://github.com/JuanGTapiaG/historia_clinica_distribuida_citus.git
cd historia_clinica_distribuida_citus
```

### 2. Construir las imágenes CentOS

```bash
docker-compose -f docker-compose-centos.yml build
```

Este paso tarda ~3–5 minutos la primera vez (descarga CentOS Stream 9 + instala PGDG + Citus RPMs).

### 3. Levantar el clúster

```bash
docker-compose -f docker-compose-centos.yml up -d
```

| Contenedor | Rol | Puerto |
|---|---|---|
| `centos_coordinator` | Nodo coordinador | `5437` (mapeado al `5432` interno) |
| `centos_worker1` | Worker 1 | Solo accesible en red interna |
| `centos_worker2` | Worker 2 | Solo accesible en red interna |

### 4. Inicializar el clúster

```bash
bash init-centos.sh
```

Salida esperada:

```
=============================================
 Inicializando Cluster Citus (CentOS)
=============================================

[1/5] Esperando a que el coordinador esté listo...
  ✔ Coordinador listo.
[2/5] Esperando a que los workers estén listos...
  ✔ centos_worker1 listo.
  ✔ centos_worker2 listo.
[3/5] Creando extensión Citus y registrando workers...
  ✔ Workers registrados.
[4/5] Creando esquema distribuido...
  ✔ Esquema creado.
[5/5] Insertando datos de ejemplo...
  ✔ Datos insertados.

=============================================
 ✔ Cluster Citus (CentOS) inicializado
=============================================
```

### 5. Conectarse al coordinador

```bash
docker exec -it centos_coordinator /usr/pgsql-16/bin/psql -U admin -d historia_clinica
```

---

## 🔍 Consultas de Validación

### Verificar workers activos

```sql
SELECT * FROM citus_get_active_worker_nodes();
```

**Resultado esperado:**
```
   node_name    | node_port
----------------+-----------
 centos_worker2 |      5432
 centos_worker1 |      5432
```

### Ver tablas distribuidas

```sql
SELECT table_name, citus_table_type, distribution_column, shard_count
FROM citus_tables;
```

**Resultado esperado:**
```
    table_name     | citus_table_type | distribution_column | shard_count
-------------------+------------------+---------------------+-------------
 atencion          | distributed      | documento_id        |          32
 diagnostico       | distributed      | documento_id        |          32
 egreso            | distributed      | documento_id        |          32
 profesional_salud | reference        | <none>              |           1
 tecnologia_salud  | distributed      | documento_id        |          32
 usuario           | distributed      | documento_id        |          32
```

### Consulta simple distribuida

```sql
SELECT nombre_completo, documento_id, sexo, edad
FROM usuario
ORDER BY nombre_completo;
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
JOIN diagnostico d ON u.documento_id = d.documento_id
    AND a.atencion_id = d.atencion_id
ORDER BY a.fecha_ingreso;
```

### Consulta con tabla replicada

```sql
SELECT
    u.nombre_completo,
    ts.descripcion_medicamento,
    ts.dosis,
    ps.nombre AS profesional,
    ps.especialidad
FROM usuario u
JOIN tecnologia_salud ts ON u.documento_id = ts.documento_id
JOIN profesional_salud ps ON ts.id_personal_salud = ps.id_personal_salud
ORDER BY u.nombre_completo;
```

### Verificar versión de PostgreSQL y Citus

```sql
SELECT version();
SELECT citus_version();
```

---

## 🧹 Detener y Limpiar

```bash
# Detener contenedores (conserva datos)
docker-compose -f docker-compose-centos.yml down

# Detener y eliminar volúmenes (⚠️ borra todos los datos)
docker-compose -f docker-compose-centos.yml down -v

# Eliminar también las imágenes construidas
docker-compose -f docker-compose-centos.yml down -v --rmi all
```

---

## 🔧 Resolución de Problemas

### El build falla al instalar Citus

```bash
# Verificar que el repo Citus está disponible
docker run --rm quay.io/centos/centos:stream9 bash -c \
  "curl -s https://install.citusdata.com/community/rpm.sh | bash && dnf list available citus*"
```

### Los workers no se registran

```bash
# Verificar que los workers están corriendo
docker exec centos_worker1 /usr/pgsql-16/bin/pg_isready -U admin -d historia_clinica
docker exec centos_worker2 /usr/pgsql-16/bin/pg_isready -U admin -d historia_clinica

# Verificar que Citus está cargado en los workers
docker exec centos_worker1 /usr/pgsql-16/bin/psql -U admin -d historia_clinica \
  -c "SHOW shared_preload_libraries;"
```

### Error de conexión al coordinador desde el host

```bash
# Verificar que el puerto 5437 está mapeado
docker port centos_coordinator

# Conectar desde el host
psql -h localhost -p 5437 -U admin -d historia_clinica
```

---

## 👤 Autor

**Juan G. Tapia G.**

- GitHub: [@JuanGTapiaG](https://github.com/JuanGTapiaG)

---

<p align="center">
  <i>Variante CentOS del laboratorio de Bases de Datos Distribuidas</i>
  <br/>
  <img src="https://img.shields.io/badge/Estado-Funcional-brightgreen?style=flat-square" alt="Estado"/>
  <img src="https://img.shields.io/badge/SO-CentOS_Stream_9-262577?style=flat-square" alt="SO"/>
  <img src="https://img.shields.io/badge/Base_de_Datos-Distribuida-blue?style=flat-square" alt="Tipo"/>
</p>
