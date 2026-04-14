-- =============================================================================
-- insert_datos.sql
-- Datos de ejemplo para la Historia Clínica Distribuida con Citus
-- =============================================================================

-- =============================================
-- 1. PROFESIONALES DE SALUD (tabla de referencia replicada)
-- =============================================
INSERT INTO profesional_salud (id_personal_salud, nombre, especialidad) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Dr. Carlos Mendoza Ríos', 'Medicina General'),
  ('b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Dra. María Fernanda López', 'Cardiología'),
  ('c3d4e5f6-a7b8-9012-cdef-123456789012', 'Dr. Andrés Felipe Gutiérrez', 'Pediatría');

-- =============================================
-- 2. USUARIOS (tabla distribuida por documento_id)
-- =============================================
INSERT INTO usuario (
    documento_id, pais_nacionalidad, nombre_completo, fecha_nacimiento, edad, sexo, genero,
    ocupacion, voluntad_anticipada, categoria_discapacidad, pais_residencia, municipio_residencia,
    etnia, comunidad_etnica, zona_residencia
) VALUES
(9307000778, 'China', 'Ariadna Valderrama-Ibarra', '1989-10-30',
    78, 'Otro', 'Masculino',
    'Engineer, maintenance (IT)', FALSE, 'Severa',
    'República Dominicana', 'Huelva', 'Indígena',
    'corrupti', 'Urbana'),
(7100168051, 'Malasia', 'Jaider Enrique Reyes Herazo', '1987-03-07',
    85, 'F', 'Masculino',
    'Hydrologist', FALSE, 'Moderada',
    'Kenya', 'Alicante', 'Mestizo',
    'at', 'Rural'),
(8851083276, 'México', 'Sebastián Zamorano Terrón', '1988-04-14',
    82, 'Otro', 'Femenino',
    'Clinical scientist, histocompatibility and immunogenetics', TRUE, 'Moderada',
    'Venezuela', 'Guadalajara', 'Indígena',
    'expedita', 'Urbana'),
(3524351848, 'Malasia', 'Jose Manuel Reguera-Pallarès', '1996-06-29',
    63, 'M', 'No binario',
    'Patent attorney', FALSE, 'Severa',
    'Samoa', 'Almería', 'Afrodescendiente',
    'qui', 'Rural'),
(1807949924, 'Nicaragua', 'Jessica Candelaria Canales Gárate', '1972-05-18',
    54, 'M', 'No binario',
    'Production assistant, radio', FALSE, 'Severa',
    'Saint Kitts y Nevis', 'León', 'Afrodescendiente',
    'voluptatum', 'Rural'),
(5444459189, 'Santa Lucía', 'Chuy Granados', '1991-04-19',
    75, 'Otro', 'No binario',
    'Clinical molecular geneticist', TRUE, 'Severa',
    'Tuvalu', 'Cádiz', 'Mestizo',
    'nam', 'Rural'),
(4200621587, 'Dominicana', 'Ariadna Valderrama Montenegro', '1971-11-17',
    30, 'M', 'No binario',
    'Insurance claims handler', TRUE, 'Moderada',
    'República Centroafricana', 'Salamanca', 'Mestizo',
    'ipsum', 'Rural'),
(3011288776, 'Trinidad y Tabago', 'Abilio Ferrera Chacón', '1979-01-14',
    28, 'Otro', 'Masculino',
    'Speech and language therapist', TRUE, 'Severa',
    'Jordania', 'Córdoba', 'Indígena',
    'odio', 'Urbana'),
(7712565174, 'Lituania', 'Jovita Villalobos Cordero', '1996-03-13',
    24, 'F', 'No binario',
    'Chief Financial Officer', FALSE, 'Moderada',
    'Zimbabwe', 'Lugo', 'Mestizo',
    'ipsam', 'Urbana'),
(2739427151, 'Haití', 'Tadeo Falcó Gascón', '1994-08-27',
    75, 'M', 'Masculino',
    'Location manager', FALSE, 'Severa',
    'Ucrania', 'Tarragona', 'Indígena',
    'quidem', 'Urbana');

-- =============================================
-- 3. ATENCIONES (tabla distribuida por documento_id)
-- =============================================
INSERT INTO atencion (documento_id, entidad_salud, fecha_ingreso, modalidad_entrega, entorno_atencion, via_ingreso, causa_atencion, fecha_triage, clasificacion_triage) VALUES
(9307000778, 'Hospital Universitario San Ignacio', '2025-01-15 08:30:00', 'Presencial', 'Hospitalario', 'Urgencias', 'Dolor torácico agudo con irradiación al brazo izquierdo', '2025-01-15 08:35:00', 'II'),
(7100168051, 'Clínica del Caribe', '2025-02-20 10:15:00', 'Presencial', 'Ambulatorio', 'Consulta Externa', 'Control de hipertensión arterial crónica', '2025-02-20 10:20:00', 'IV'),
(8851083276, 'Hospital Pablo Tobón Uribe', '2025-03-05 14:00:00', 'Telemedicina', 'Domiciliario', 'Remisión', 'Seguimiento post-operatorio de apendicectomía', '2025-03-05 14:10:00', 'V'),
(3524351848, 'Fundación Valle del Lili', '2025-03-18 09:00:00', 'Presencial', 'Hospitalario', 'Urgencias', 'Fractura expuesta de tibia derecha', '2025-03-18 09:05:00', 'I'),
(1807949924, 'Hospital General de Medellín', '2025-04-02 16:45:00', 'Presencial', 'Ambulatorio', 'Consulta Externa', 'Evaluación de diabetes mellitus tipo 2', '2025-04-02 16:50:00', 'III'),
(5444459189, 'Clínica Las Américas', '2025-04-10 11:30:00', 'Presencial', 'Hospitalario', 'Urgencias', 'Crisis asmática severa con dificultad respiratoria', '2025-04-10 11:32:00', 'II'),
(4200621587, 'Hospital Infantil de San José', '2025-05-01 07:00:00', 'Presencial', 'Ambulatorio', 'Consulta Externa', 'Control prenatal - semana 28 de gestación', '2025-05-01 07:10:00', 'V'),
(3011288776, 'Clínica Shaio', '2025-05-15 20:00:00', 'Presencial', 'Hospitalario', 'Urgencias', 'Accidente cerebrovascular isquémico agudo', '2025-05-15 20:02:00', 'I'),
(7712565174, 'Hospital San Vicente Fundación', '2025-06-01 13:00:00', 'Telemedicina', 'Domiciliario', 'Remisión', 'Seguimiento de tratamiento oncológico - linfoma', '2025-06-01 13:15:00', 'III'),
(2739427151, 'Centro Médico Imbanaco', '2025-06-20 09:30:00', 'Presencial', 'Ambulatorio', 'Consulta Externa', 'Evaluación ortopédica por dolor lumbar crónico', '2025-06-20 09:40:00', 'IV');

-- =============================================
-- 4. TECNOLOGÍAS EN SALUD (tabla distribuida por documento_id)
-- =============================================
INSERT INTO tecnologia_salud (tecnologia_id, documento_id, atencion_id, descripcion_medicamento, dosis, via_administracion, frecuencia, dias_tratamiento, unidades_aplicadas, id_personal_salud, finalidad_tecnologia) VALUES
('d4e5f6a7-b8c9-0123-defa-234567890123', 9307000778, 1, 'Aspirina 100mg', '100mg', 'Oral', 'Cada 24 horas', 30, 30, 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Antiagregante plaquetario para prevención cardiovascular'),
('e5f6a7b8-c9d0-1234-efab-345678901234', 7100168051, 2, 'Losartán 50mg', '50mg', 'Oral', 'Cada 12 horas', 90, 180, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Control de presión arterial en hipertensión crónica'),
('f6a7b8c9-d0e1-2345-fabc-456789012345', 8851083276, 3, 'Amoxicilina 500mg', '500mg', 'Oral', 'Cada 8 horas', 7, 21, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Profilaxis antibiótica post-quirúrgica'),
('a7b8c9d0-e1f2-3456-abcd-567890123456', 3524351848, 4, 'Morfina 10mg/ml', '10mg', 'Intravenosa', 'Cada 6 horas PRN', 5, 20, 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Manejo del dolor agudo post-fractura'),
('b8c9d0e1-f2a3-4567-bcde-678901234567', 1807949924, 5, 'Metformina 850mg', '850mg', 'Oral', 'Cada 12 horas', 180, 360, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Control glucémico en diabetes mellitus tipo 2'),
('c9d0e1f2-a3b4-5678-cdef-789012345678', 5444459189, 6, 'Salbutamol inhalador 100mcg', '200mcg', 'Inhalatoria', 'Cada 4 horas', 7, 42, 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Broncodilatador para crisis asmática'),
('d0e1f2a3-b4c5-6789-defa-890123456789', 4200621587, 7, 'Ácido fólico 1mg', '1mg', 'Oral', 'Cada 24 horas', 84, 84, 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Suplementación prenatal - prevención defectos del tubo neural'),
('e1f2a3b4-c5d6-7890-efab-901234567890', 3011288776, 8, 'Alteplasa 50mg', '0.9mg/kg', 'Intravenosa', 'Dosis única', 1, 1, 'b2c3d4e5-f6a7-8901-bcde-f12345678901', 'Trombólisis en ACV isquémico agudo'),
('f2a3b4c5-d6e7-8901-fabc-012345678901', 7712565174, 9, 'Ciclofosfamida 500mg', '750mg/m2', 'Intravenosa', 'Cada 21 días', 126, 6, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Quimioterapia - protocolo CHOP para linfoma'),
('a3b4c5d6-e7f8-9012-abcd-123456789012', 2739427151, 10, 'Ibuprofeno 600mg', '600mg', 'Oral', 'Cada 8 horas', 14, 42, 'c3d4e5f6-a7b8-9012-cdef-123456789012', 'Antiinflamatorio para dolor lumbar crónico');

-- =============================================
-- 5. DIAGNÓSTICOS (tabla distribuida por documento_id)
-- =============================================
INSERT INTO diagnostico (documento_id, atencion_id, tipo_diagnostico_ingreso, diagnostico_ingreso, tipo_diagnostico_egreso, diagnostico_egreso, diagnostico_rel1, diagnostico_rel2, diagnostico_rel3) VALUES
(9307000778, 1, 'Presuntivo', 'I20.0 - Angina inestable', 'Confirmado', 'I20.0 - Angina inestable', 'I25.1 - Enfermedad aterosclerótica del corazón', 'I10 - Hipertensión esencial', NULL),
(7100168051, 2, 'Confirmado', 'I10 - Hipertensión esencial primaria', 'Confirmado', 'I10 - Hipertensión esencial primaria', 'E78.0 - Hipercolesterolemia pura', NULL, NULL),
(8851083276, 3, 'Confirmado', 'K35.8 - Apendicitis aguda', 'Confirmado', 'Z09.0 - Seguimiento post-quirúrgico', 'K35.8 - Apendicitis aguda, resuelta', NULL, NULL),
(3524351848, 4, 'Presuntivo', 'S82.1 - Fractura de extremo proximal de tibia', 'Confirmado', 'S82.1 - Fractura de tibia, reducción abierta', 'T79.3 - Infección post-traumática', 'M79.6 - Dolor en miembro', NULL),
(1807949924, 5, 'Confirmado', 'E11.9 - Diabetes mellitus tipo 2 sin complicaciones', 'Confirmado', 'E11.9 - Diabetes mellitus tipo 2 controlada', 'E78.5 - Hiperlipidemia no especificada', 'I10 - Hipertensión esencial', NULL),
(5444459189, 6, 'Presuntivo', 'J45.1 - Asma no alérgica con exacerbación aguda', 'Confirmado', 'J45.1 - Asma con exacerbación aguda resuelta', 'J96.0 - Insuficiencia respiratoria aguda', NULL, NULL),
(4200621587, 7, 'Confirmado', 'Z34.0 - Supervisión de embarazo normal primero', 'Confirmado', 'Z34.2 - Supervisión embarazo normal semana 28', 'O99.0 - Anemia complicando embarazo', NULL, NULL),
(3011288776, 8, 'Presuntivo', 'I63.9 - Infarto cerebral no especificado', 'Confirmado', 'I63.3 - Infarto cerebral por trombosis arterias cerebrales', 'I10 - Hipertensión esencial', 'E11.9 - Diabetes mellitus tipo 2', 'I48 - Fibrilación auricular'),
(7712565174, 9, 'Confirmado', 'C83.3 - Linfoma difuso de células B grandes', 'Confirmado', 'C83.3 - Linfoma DCBG en tratamiento', 'D69.6 - Trombocitopenia no especificada', NULL, NULL),
(2739427151, 10, 'Presuntivo', 'M54.5 - Lumbago no especificado', 'Confirmado', 'M51.1 - Hernia discal lumbar con radiculopatía', 'M54.4 - Lumbago con ciática', 'G55.1 - Compresión de raíces nerviosas', NULL);

-- =============================================
-- 6. EGRESOS (tabla distribuida por documento_id)
-- =============================================
INSERT INTO egreso (documento_id, atencion_id, fecha_salida, condicion_salida, diagnostico_muerte, codigo_prestador, tipo_incapacidad, dias_incapacidad, dias_lic_maternidad, alergias, antecedente_familiar, riesgos_ocupacionales, responsable_egreso) VALUES
(9307000778, 1, '2025-01-18 16:00:00', 'Mejorado', NULL, 'IPS-001234', 'Temporal', 15, 0, 'Penicilina', 'Padre con infarto agudo de miocardio a los 55 años', 'Estrés laboral', 'Dr. Carlos Mendoza Ríos'),
(7100168051, 2, '2025-02-20 11:30:00', 'Mejorado', NULL, 'IPS-005678', NULL, 0, 0, 'Ninguna conocida', 'Madre con hipertensión arterial', 'Exposición a calor extremo', 'Dr. Carlos Mendoza Ríos'),
(8851083276, 3, '2025-03-05 14:45:00', 'Mejorado', NULL, 'IPS-009012', 'Temporal', 5, 0, 'Sulfonamidas', 'Sin antecedentes relevantes', 'Ninguno identificado', 'Dra. María Fernanda López'),
(3524351848, 4, '2025-04-01 10:00:00', 'Mejorado', NULL, 'IPS-003456', 'Temporal', 60, 0, 'Ninguna conocida', 'Abuela materna con osteoporosis', 'Trabajo en alturas', 'Dr. Andrés Felipe Gutiérrez'),
(1807949924, 5, '2025-04-02 18:00:00', 'Mejorado', NULL, 'IPS-007890', NULL, 0, 0, 'AINEs (Diclofenaco)', 'Ambos padres con diabetes mellitus tipo 2', 'Sedentarismo laboral', 'Dr. Carlos Mendoza Ríos'),
(5444459189, 6, '2025-04-13 09:00:00', 'Mejorado', NULL, 'IPS-002345', 'Temporal', 7, 0, 'Ácaros del polvo', 'Madre y hermano con asma bronquial', 'Exposición a químicos de laboratorio', 'Dra. María Fernanda López'),
(4200621587, 7, '2025-05-01 08:30:00', 'Mejorado', NULL, 'IPS-006789', NULL, 0, 84, 'Ninguna conocida', 'Sin antecedentes relevantes', 'Ninguno identificado', 'Dr. Andrés Felipe Gutiérrez'),
(3011288776, 8, '2025-06-01 12:00:00', 'Mejorado', NULL, 'IPS-001111', 'Permanente', 180, 0, 'Contraste yodado', 'Padre con ACV a los 62 años, madre con fibrilación auricular', 'Estrés laboral crónico', 'Dra. María Fernanda López'),
(7712565174, 9, '2025-06-03 15:00:00', 'Mejorado', NULL, 'IPS-002222', 'Temporal', 21, 0, 'Metoclopramida', 'Tío materno con linfoma no Hodgkin', 'Exposición a radiación ionizante', 'Dr. Carlos Mendoza Ríos'),
(2739427151, 10, '2025-06-22 11:00:00', 'Mejorado', NULL, 'IPS-003333', 'Temporal', 30, 0, 'Ninguna conocida', 'Padre con hernia discal lumbar', 'Carga de peso excesivo, posturas forzadas', 'Dr. Andrés Felipe Gutiérrez');
