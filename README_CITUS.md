<p align="center">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Citus-1A1A2E?style=for-the-badge&logo=postgresql&logoColor=00D4AA" alt="Citus"/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Express-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express"/>
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"/>
</p>

# 🏥 Historia Clínica Distribuida con PostgreSQL + Citus

> Sistema de base de datos distribuida para la gestión de historias clínicas electrónicas, implementado con **PostgreSQL** y la extensión **Citus** para fragmentación (sharding) y escalado horizontal automático. Incluye una **API REST** con Node.js + Express para consultar los datos del clúster.

---

## 📋 Tabla de Contenidos

- [Fundamento Teórico](#-fundamento-teórico)
- [Arquitectura del Clúster](#-arquitectura-del-clúster)
- [Estrategia de Distribución](#-estrategia-de-distribución)
- [Modelo Entidad-Relación](#-modelo-entidad-relación)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Despliegue](#-instalación-y-despliegue)
- [API REST](#-api-rest)
- [Consultas de Validación](#-consultas-de-validación)
- [Esquema de la Base de Datos](#-esquema-de-la-base-de-datos)
- [Detener y Limpiar](#-detener-y-limpiar)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Autor](#-autor)
- [Licencia](#-licencia)

---

## 📚 Fundamento Teórico

### ¿Qué es una Base de Datos Distribuida?

Un **sistema de bases de datos distribuidas** es un conjunto de múltiples bases de datos lógicamente relacionadas,
dispersas en diferentes nodos físicos o ubicaciones geográficas y conectadas por una red. Aunque los datos están
distribuidos, el sistema se presenta al usuario como una **sola unidad unificada y coherente**.

| Característica | Descripción |
|---|---|
| **Distribución** | Los nodos pueden ser servidores separados geográficamente o máquinas virtuales |
| **Autonomía Local** | Cada sitio puede procesar datos de manera local e independiente |
| **Transparencia** | El usuario no necesita saber dónde residen los datos para acceder a ellos |

### Ventajas

| Ventaja | Descripción |
|---|---|
| 📈 **Escalabilidad** | Escalar horizontalmente agregando más nodos al clúster |
| 🛡️ **Tolerancia a fallos** | Si un nodo falla, el sistema sigue funcionando mediante réplicas |
| ⚡ **Rendimiento** | Menor latencia al acceder a datos locales y procesamiento paralelo |

### Tipos de Bases de Datos Distribuidas

- **Homogéneas**: Todos los nodos utilizan el mismo SGBD (como en este proyecto con PostgreSQL + Citus).
- **Heterogéneas**: Los nodos pueden utilizar diferentes SGBD, dificultando la integración.

### ¿Qué es Citus?

**[Citus](https://www.citusdata.com/)** es la extensión líder para convertir PostgreSQL en una base de datos distribuida mediante **sharding** de datos en múltiples nodos. Es ideal para:

- Aplicaciones SaaS multi-inquilino
- Análisis de datos en tiempo real
- Sistemas que necesitan escalado horizontal manteniendo la compatibilidad SQL completa

### Ejemplos de Sistemas Distribuidos

| Tipo | Ejemplos |
|---|---|
| **NoSQL** | MongoDB, Cassandra, DynamoDB |
| **Relacional (con soporte distribuido)** | Oracle, PostgreSQL + Citus, Microsoft SQL Server |

---

## 🏗️ Arquitectura del Clúster

El clúster está compuesto por **3 nodos** Docker que se comunican a través de una red interna, más un servicio de **API REST** opcional:

```
                         ┌────────────────────────┐
                         │      API REST           │
                         │  Node.js + Express      │
                         │  Puerto: 3000           │
                         └──────────┬─────────────┘
                                    │ pg (puerto 5436)
                     ┌──────────────▼──────────────────┐
                     │       COORDINADOR (Citus)        │
                     │   Puerto externo: 5436 → 5432    │
                     │   • Recibe todas las consultas    │
                     │   • Planifica y distribuye queries │
                     │   • Agrega resultados             │
                     └──────────┬──────────┬─────────────┘
                                │          │
                   ┌────────────┘          └─────────────┐
                   │                                     │
          ┌────────▼─────────┐              ┌────────────▼────────┐
          │   WORKER 1       │              │   WORKER 2          │
          │   Puerto: 5432   │              │   Puerto: 5432      │
          │   • Shards pares │              │   • Shards impares  │
          │   • Almacena     │              │   • Almacena        │
          │     fragmentos   │              │     fragmentos      │
          └──────────────────┘              └─────────────────────┘
```

---

## 📊 Estrategia de Distribución

| Tabla | Tipo | Columna de distribución | Descripción |
|---|---|---|---|
| `usuario` | Distribuida | `documento_id` | Tabla principal de pacientes |
| `atencion` | Distribuida | `documento_id` | Atenciones médicas co-localizadas con usuario |
| `tecnologia_salud` | Distribuida | `documento_id` | Medicamentos y tecnologías aplicadas |
| `diagnostico` | Distribuida | `documento_id` | Diagnósticos de ingreso y egreso |
| `egreso` | Distribuida | `documento_id` | Información de salida del paciente |
| `profesional_salud` | Replicada | — | Copia completa en cada worker |

> 💡 **Co-localización:** Todas las tablas distribuidas usan `documento_id` como columna de distribución, lo que garantiza que los datos de un mismo paciente residan en el mismo shard, optimizando los JOINs distribuidos.

---

## 📐 Modelo Entidad-Relación

<p align="center">
  <img src="MER_historia_clinica.png" alt="Modelo Entidad-Relación" width="800"/>
</p>

El modelo consta de **6 tablas** interrelacionadas que representan el flujo completo de una atención médica:

1. **`usuario`** → Datos demográficos del paciente (tabla central).
2. **`atencion`** → Registro de cada atención médica recibida.
3. **`tecnologia_salud`** → Medicamentos y tecnologías aplicadas durante la atención.
4. **`diagnostico`** → Diagnósticos de ingreso, egreso y relacionados.
5. **`egreso`** → Información de salida, incapacidades y antecedentes.
6. **`profesional_salud`** → Catálogo de profesionales de salud (tabla de referencia replicada).

---

## 📁 Estructura del Proyecto

```
historia_clinica_distribuida_citus/
│
├── 📄 docker-compose-citus.yml   # Orquestación de contenedores (coordinador + 2 workers)
├── 🔧 init-citus.sh              # Script de inicialización automática del clúster
├── 🗃️ schema_citus.sql           # Esquema DDL con tablas distribuidas y replicadas
├── 📊 insert_datos.sql           # Datos de ejemplo para las 6 tablas (10 pacientes)
├── 🖼️ MER_historia_clinica.png   # Diagrama Entidad-Relación del modelo de datos
├── 📖 README.md                  # Documentación principal del proyecto
├── 📖 README_CITUS.md            # Este archivo — documentación técnica Citus
│
├── api/                           # API REST para consultar el clúster
│   ├── server.js                  # Servidor Express con endpoints de consulta
│   ├── package.json               # Dependencias (express, pg, cors)
│   └── package-lock.json          # Lock de dependencias
│
├── docs/                          # Documentación adicional (reservado)
└── scripts/                       # Scripts auxiliares (reservado)
```

---

## ✅ Requisitos Previos

| Herramienta | Versión mínima | Descripción |
|---|---|---|
| [Docker](https://docs.docker.com/get-docker/) | 20.10+ | Motor de contenedores |
| [Docker Compose](https://docs.docker.com/compose/install/) | 2.0+ | Orquestación de contenedores |
| [Node.js](https://nodejs.org/) | 18+ | Requerido para la API REST |
| [Git](https://git-scm.com/) | 2.30+ | Control de versiones |
| Bash | 4.0+ | Shell para el script de inicialización |

---

## 🚀 Instalación y Despliegue

### 1. Clonar el repositorio

```bash
git clone https://github.com/JuanGTapiaG/historia_clinica_distribuida_citus.git
cd historia_clinica_distribuida_citus
```

### 2. Levantar los servicios con Docker Compose

```bash
docker-compose -f docker-compose-citus.yml up -d
```

Esto levanta **3 contenedores**:

| Contenedor | Rol | Puerto |
|---|---|---|
| `citus_coordinator` | Nodo coordinador | `5436` (mapeado al `5432` interno) |
| `citus_worker1` | Worker 1 | Solo accesible en red interna |
| `citus_worker2` | Worker 2 | Solo accesible en red interna |

### 3. Inicializar el clúster

Ejecuta el script de inicialización que configura todo automáticamente:

```bash
bash init-citus.sh
```

El script realiza los siguientes pasos:

```
[1/5] ⏳ Esperando a que el coordinador esté listo...
[2/5] ⏳ Esperando a que los workers estén listos...
[3/5] 🔌 Creando extensión Citus y registrando workers...
[4/5] 🗃️ Creando esquema distribuido (tablas y shards)...
[5/5] 📊 Insertando datos de ejemplo...
  ✔ Cluster Citus inicializado correctamente
```

### 4. Conectarse al coordinador

```bash
docker exec -it citus_coordinator psql -U admin -d historia_clinica
```

### 5. (Opcional) Inicialización manual

Si prefieres ejecutar los pasos manualmente:

```bash
# Crear extensión Citus
docker exec -it citus_coordinator psql -U admin -d historia_clinica \
  -c "CREATE EXTENSION IF NOT EXISTS citus;"

# Registrar workers
docker exec -it citus_coordinator psql -U admin -d historia_clinica \
  -c "SELECT citus_add_node('citus_worker1', 5432);"
docker exec -it citus_coordinator psql -U admin -d historia_clinica \
  -c "SELECT citus_add_node('citus_worker2', 5432);"

# Crear esquema distribuido
docker exec -i citus_coordinator psql -U admin -d historia_clinica < schema_citus.sql

# Insertar datos de ejemplo
docker exec -i citus_coordinator psql -U admin -d historia_clinica < insert_datos.sql
```

---

## 🌐 API REST

El proyecto incluye una API REST construida con **Node.js + Express** que permite consultar los datos del clúster Citus mediante endpoints HTTP.

### Configuración de la API

```bash
cd api
npm install
node server.js
```

La API se expone en **http://localhost:3000** y se conecta al coordinador Citus en el puerto `5436`.

### Endpoints disponibles

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/health` | Health check del servicio y conexión a la BD |
| `GET` | `/api/pacientes` | Listar todos los pacientes (límite 50) |
| `GET` | `/api/pacientes/:id` | Obtener un paciente por `documento_id` |
| `GET` | `/api/consulta-distribuida` | Consulta con JOINs distribuidos (usuario + atención + diagnóstico) |

### Ejemplos de uso

```bash
# Health check
curl http://localhost:3000/api/health

# Listar pacientes
curl http://localhost:3000/api/pacientes

# Buscar paciente por documento
curl http://localhost:3000/api/pacientes/9307000778

# Consulta distribuida con JOINs
curl http://localhost:3000/api/consulta-distribuida
```

### Respuesta de ejemplo — `/api/health`

```json
{
  "status": "ok",
  "service": "API Historia Clinica",
  "database": "Citus Cluster"
}
```

### Dependencias de la API

| Paquete | Versión | Uso |
|---|---|---|
| `express` | ^5.2.1 | Framework HTTP |
| `pg` | ^8.20.0 | Cliente PostgreSQL |
| `cors` | ^2.8.6 | Middleware CORS |

---

## 🔍 Consultas de Validación

Una vez inicializado el clúster, puedes ejecutar las siguientes consultas desde `psql` para verificar su correcto funcionamiento:

### Verificar workers activos

```sql
SELECT * FROM citus_get_active_worker_nodes();
```

**Resultado esperado:** 2 workers registrados (`citus_worker1` y `citus_worker2`).

### Ver tablas distribuidas

```sql
SELECT * FROM citus_tables;
```

### Consulta simple distribuida

```sql
SELECT nombre_completo, documento_id, sexo, edad
FROM usuario
WHERE documento_id > 0;
```

### Consulta con JOINs distribuidos (co-localizados)

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

## 🗃️ Esquema de la Base de Datos

### Tabla `usuario` (distribuida)

| Columna | Tipo | Descripción |
|---|---|---|
| `documento_id` | `BIGINT` PK | Identificador único del paciente |
| `pais_nacionalidad` | `VARCHAR(100)` | País de nacionalidad |
| `nombre_completo` | `VARCHAR(255)` | Nombre completo del paciente |
| `fecha_nacimiento` | `DATE` | Fecha de nacimiento |
| `edad` | `INT` | Edad del paciente |
| `sexo` | `VARCHAR(10)` | Sexo biológico |
| `genero` | `VARCHAR(20)` | Identidad de género |
| `ocupacion` | `VARCHAR(100)` | Ocupación actual |
| `voluntad_anticipada` | `BOOLEAN` | Si tiene voluntad anticipada |
| `categoria_discapacidad` | `VARCHAR(50)` | Categoría de discapacidad |
| `pais_residencia` | `VARCHAR(100)` | País de residencia |
| `municipio_residencia` | `VARCHAR(100)` | Municipio de residencia |
| `etnia` | `VARCHAR(50)` | Etnia |
| `comunidad_etnica` | `VARCHAR(100)` | Comunidad étnica |
| `zona_residencia` | `VARCHAR(50)` | Zona (Urbana/Rural) |

### Tabla `atencion` (distribuida)

| Columna | Tipo | Descripción |
|---|---|---|
| `atencion_id` | `SERIAL` | Identificador de la atención |
| `documento_id` | `BIGINT` PK/FK | Referencia al paciente |
| `entidad_salud` | `VARCHAR(255)` | Institución de salud |
| `fecha_ingreso` | `TIMESTAMP` | Fecha y hora de ingreso |
| `modalidad_entrega` | `VARCHAR(50)` | Presencial / Telemedicina |
| `entorno_atencion` | `VARCHAR(50)` | Entorno de la atención |
| `via_ingreso` | `VARCHAR(50)` | Vía de ingreso |
| `causa_atencion` | `TEXT` | Motivo de la atención |
| `fecha_triage` | `TIMESTAMP` | Fecha del triage |
| `clasificacion_triage` | `VARCHAR(10)` | Clasificación de urgencia (I-V) |

### Tabla `tecnologia_salud` (distribuida)

| Columna | Tipo | Descripción |
|---|---|---|
| `tecnologia_id` | `UUID` | Identificador de la tecnología |
| `documento_id` | `BIGINT` PK/FK | Referencia al paciente |
| `atencion_id` | `INT` | Referencia a la atención |
| `descripcion_medicamento` | `VARCHAR(255)` | Nombre del medicamento |
| `dosis` | `VARCHAR(50)` | Dosis administrada |
| `via_administracion` | `VARCHAR(50)` | Vía de administración |
| `frecuencia` | `VARCHAR(50)` | Frecuencia de administración |
| `dias_tratamiento` | `INT` | Duración del tratamiento |
| `unidades_aplicadas` | `INT` | Unidades aplicadas |
| `id_personal_salud` | `UUID` | Profesional responsable |
| `finalidad_tecnologia` | `VARCHAR(255)` | Finalidad de la tecnología |

### Tabla `diagnostico` (distribuida)

| Columna | Tipo | Descripción |
|---|---|---|
| `diagnostico_id` | `SERIAL` | Identificador del diagnóstico |
| `documento_id` | `BIGINT` PK/FK | Referencia al paciente |
| `atencion_id` | `INT` | Referencia a la atención |
| `tipo_diagnostico_ingreso` | `VARCHAR(50)` | Tipo (Presuntivo/Confirmado) |
| `diagnostico_ingreso` | `VARCHAR(255)` | Diagnóstico al ingreso |
| `tipo_diagnostico_egreso` | `VARCHAR(50)` | Tipo al egreso |
| `diagnostico_egreso` | `VARCHAR(255)` | Diagnóstico al egreso |
| `diagnostico_rel1` | `VARCHAR(255)` | Diagnóstico relacionado 1 |
| `diagnostico_rel2` | `VARCHAR(255)` | Diagnóstico relacionado 2 |
| `diagnostico_rel3` | `VARCHAR(255)` | Diagnóstico relacionado 3 |

### Tabla `egreso` (distribuida)

| Columna | Tipo | Descripción |
|---|---|---|
| `egreso_id` | `SERIAL` | Identificador del egreso |
| `documento_id` | `BIGINT` PK/FK | Referencia al paciente |
| `atencion_id` | `INT` | Referencia a la atención |
| `fecha_salida` | `TIMESTAMP` | Fecha de salida |
| `condicion_salida` | `VARCHAR(100)` | Condición al momento de salida |
| `diagnostico_muerte` | `VARCHAR(255)` | Diagnóstico de muerte (si aplica) |
| `codigo_prestador` | `VARCHAR(20)` | Código del prestador |
| `tipo_incapacidad` | `VARCHAR(100)` | Tipo de incapacidad |
| `dias_incapacidad` | `INT` | Días de incapacidad |
| `dias_lic_maternidad` | `INT` | Días de licencia de maternidad |
| `alergias` | `TEXT` | Alergias conocidas |
| `antecedente_familiar` | `TEXT` | Antecedentes familiares |
| `riesgos_ocupacionales` | `TEXT` | Riesgos ocupacionales |
| `responsable_egreso` | `VARCHAR(255)` | Profesional responsable del egreso |

### Tabla `profesional_salud` (replicada)

| Columna | Tipo | Descripción |
|---|---|---|
| `id_personal_salud` | `UUID` PK | Identificador único del profesional |
| `nombre` | `VARCHAR(255)` | Nombre del profesional |
| `especialidad` | `VARCHAR(100)` | Especialidad médica |

---

## 🧹 Detener y Limpiar

```bash
# Detener contenedores (conserva datos)
docker-compose -f docker-compose-citus.yml down

# Detener y eliminar volúmenes (⚠️ borra todos los datos)
docker-compose -f docker-compose-citus.yml down -v
```

---

## 🛠️ Tecnologías Utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| **PostgreSQL** | 14+ | Motor de base de datos relacional |
| **Citus** | 11.2 | Extensión de distribución y sharding |
| **Docker** | 20.10+ | Contenerización de servicios |
| **Docker Compose** | 2.0+ | Orquestación multi-contenedor |
| **Node.js** | 18+ | Runtime para la API REST |
| **Express** | 5.x | Framework HTTP para la API |
| **Bash** | 4.0+ | Automatización de la inicialización |

---

## 👤 Autores

**Omar A. Gomez F.**
**Juan G. Tapia G.**

---

## 📄 Licencia

Este proyecto es de uso académico y educativo. Siéntete libre de usarlo como referencia para aprender sobre bases de datos distribuidas con PostgreSQL y Citus.

---

<p align="center">
  <i>Desarrollado como laboratorio de Bases de Datos Distribuidas</i>
  <br/>
  <img src="https://img.shields.io/badge/Estado-Funcional-brightgreen?style=flat-square" alt="Estado"/>
  <img src="https://img.shields.io/badge/Base_de_Datos-Distribuida-blue?style=flat-square" alt="Tipo"/>
  <img src="https://img.shields.io/badge/API-REST-orange?style=flat-square" alt="API"/>
</p>
