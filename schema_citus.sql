
-- Crear extensión Citus (solo en el coordinador)
CREATE EXTENSION IF NOT EXISTS citus;

-- Tabla usuario (distribuida por documento_id)
CREATE TABLE usuario (
    documento_id BIGINT PRIMARY KEY,
    pais_nacionalidad VARCHAR(100),
    nombre_completo VARCHAR(255),
    fecha_nacimiento DATE,
    edad INT,
    sexo VARCHAR(10),
    genero VARCHAR(20),
    ocupacion VARCHAR(100),
    voluntad_anticipada BOOLEAN,
    categoria_discapacidad VARCHAR(50),
    pais_residencia VARCHAR(100),
    municipio_residencia VARCHAR(100),
    etnia VARCHAR(50),
    comunidad_etnica VARCHAR(100),
    zona_residencia VARCHAR(50)
);
SELECT create_distributed_table('usuario', 'documento_id');

-- Tabla atención (distribuida por documento_id, relacionada con usuario)
-- La PRIMARY KEY incluye documento_id para cumplir requisito de Citus
CREATE TABLE atencion (
    atencion_id SERIAL,
    documento_id BIGINT NOT NULL,
    entidad_salud VARCHAR(255),
    fecha_ingreso TIMESTAMP,
    modalidad_entrega VARCHAR(50),
    entorno_atencion VARCHAR(50),
    via_ingreso VARCHAR(50),
    causa_atencion TEXT,
    fecha_triage TIMESTAMP,
    clasificacion_triage VARCHAR(10),
    PRIMARY KEY (documento_id, atencion_id),
    FOREIGN KEY (documento_id) REFERENCES usuario(documento_id)
);
SELECT create_distributed_table('atencion', 'documento_id');

-- Tabla tecnologia_salud (relacionada con atención, distribuida por documento_id)
-- La PRIMARY KEY incluye documento_id para cumplir requisito de Citus
CREATE TABLE tecnologia_salud (
    tecnologia_id UUID,
    documento_id BIGINT NOT NULL,
    atencion_id INT,
    descripcion_medicamento VARCHAR(255),
    dosis VARCHAR(50),
    via_administracion VARCHAR(50),
    frecuencia VARCHAR(50),
    dias_tratamiento INT,
    unidades_aplicadas INT,
    id_personal_salud UUID,
    finalidad_tecnologia VARCHAR(255),
    PRIMARY KEY (documento_id, tecnologia_id),
    FOREIGN KEY (documento_id) REFERENCES usuario(documento_id)
);
SELECT create_distributed_table('tecnologia_salud', 'documento_id');

-- Tabla diagnostico (relacionada con atención, distribuida por documento_id)
-- La PRIMARY KEY incluye documento_id para cumplir requisito de Citus
CREATE TABLE diagnostico (
    diagnostico_id SERIAL,
    documento_id BIGINT NOT NULL,
    atencion_id INT,
    tipo_diagnostico_ingreso VARCHAR(50),
    diagnostico_ingreso VARCHAR(255),
    tipo_diagnostico_egreso VARCHAR(50),
    diagnostico_egreso VARCHAR(255),
    diagnostico_rel1 VARCHAR(255),
    diagnostico_rel2 VARCHAR(255),
    diagnostico_rel3 VARCHAR(255),
    PRIMARY KEY (documento_id, diagnostico_id),
    FOREIGN KEY (documento_id) REFERENCES usuario(documento_id)
);
SELECT create_distributed_table('diagnostico', 'documento_id');

-- Tabla egreso (distribuida por documento_id)
-- La PRIMARY KEY incluye documento_id para cumplir requisito de Citus
CREATE TABLE egreso (
    egreso_id SERIAL,
    documento_id BIGINT NOT NULL,
    atencion_id INT,
    fecha_salida TIMESTAMP,
    condicion_salida VARCHAR(100),
    diagnostico_muerte VARCHAR(255),
    codigo_prestador VARCHAR(20),
    tipo_incapacidad VARCHAR(100),
    dias_incapacidad INT,
    dias_lic_maternidad INT,
    alergias TEXT,
    antecedente_familiar TEXT,
    riesgos_ocupacionales TEXT,
    responsable_egreso VARCHAR(255),
    PRIMARY KEY (documento_id, egreso_id),
    FOREIGN KEY (documento_id) REFERENCES usuario(documento_id)
);
SELECT create_distributed_table('egreso', 'documento_id');

-- Tabla profesional_salud (tabla de referencia replicada)
CREATE TABLE profesional_salud (
    id_personal_salud UUID PRIMARY KEY,
    nombre VARCHAR(255),
    especialidad VARCHAR(100)
);
SELECT create_reference_table('profesional_salud');
