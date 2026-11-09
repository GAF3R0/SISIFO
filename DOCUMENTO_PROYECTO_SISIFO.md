# Documento Técnico y Clínico: Proyecto Sísifo
**Herramienta de Evaluación de Riesgo de Depresión Mediante PHQ-9 y Análisis Facial con IA**

---

## 1. Planteamiento del Problema que Busca Resolver Sísifo

### 1.1. Contexto y Relevancia Epidemiológica
Los trastornos depresivos constituyen una de las principales causas mundiales de discapacidad según la Organización Mundial de la Salud (OMS). A pesar de su alta prevalencia, una gran proporción de los casos no es diagnosticada oportunamente o recibe un abordaje tardío. En el contexto de la práctica clínica cotidiana, la saturación del sistema de salud y la limitación de tiempo por consulta dificultan una evaluación longitudinal y multidimensional profunda.

### 1.2. Limitaciones del Diagnóstico Basado Exclusivamente en Autorreporte
En la práctica psicológica y psiquiátrica estándar, el tamizaje inicial descansa en cuestionarios estandarizados de autorreporte, predominantemente el **PHQ-9 (Patient Health Questionnaire-9)**. Aunque el PHQ-9 cuenta con alta sensibilidad psicométrica, sufre de sesgos intrínsecos al sujeto:
* **Minimización de síntomas:** Pacientes que, por estigma social, mecanismos de defensa, culpa o miedo al diagnóstico, minimizan u omiten conscientemente o inconscientemente la severidad de su malestar.
* **Aplanamiento afectivo y disimulo:** Pacientes con depresión severa o cuadros melancólicos que pueden aparentar estabilidad en sus respuestas numéricas, pero cuyos patrones neuromusculares involuntarios reflejan un aplanamiento o desregulación afectiva marcada.
* **Ausencia de marcadores objetivos:** La falta de biomarcadores complementarios deja al terapeuta sin una herramienta rápida que contraste lo que el paciente *dice* con lo que sus respuestas fisiológicas y gestuales *expresan*.

### 1.3. Riesgos de Privacidad con Datos Médicos y Biométricos
El uso de inteligencia artificial en salud suele depender de arquitecturas centralizadas en la nube donde se envían fotografías, videos o historiales clínicos sin control estricto de custodia. Esto transgrede la legislación de protección de datos personales y sensibles (como la **LFPDPPP** y las normas oficiales mexicanas **NOM-004-SSA3-2012** y **NOM-024-SSA3-2012**).

### 1.4. Definición del Problema Central
> *¿Cómo proporcionar al profesional de la salud mental una herramienta ágil, no invasiva y científicamente respaldada que aumente la sensibilidad diagnóstica mediante la fusión de psicometría estandarizada y biomarcadores faciales, garantizando al mismo tiempo la privacidad absoluta del paciente mediante procesamiento local en el dispositivo (Edge AI) y trazabilidad clínica inmutable?*

---

## 2. Diseño del Sistema y Flujo Clínico

### 2.1. Diseño Conceptual del Flujo Clínico
El diseño de Sísifo no busca reemplazar el juicio clínico, sino funcionar como un **Sistema de Soporte a la Decisión Clínica (CDSS - Clinical Decision Support System)**:

```
[Autenticación Profesional]
         │
         ▼
[Consentimiento Informado Digital (LFPDPPP)]
         │
         ▼
[Cuestionario PHQ-9 (9 Ítems)] ───┐
         │                        │
         ▼                        ├──► [Motor de Fusión Multimodal]
[Fotografía Facial Frontal (FACS)]─┘       │
                                           ▼
                                [Índice de Riesgo + Detección de Discrepancias]
                                           │
                                           ├─► [Almacenamiento Cifrado SQLCipher]
                                           ├─► [Bitácora de Auditoría Append-Only]
                                           └─► [Reporte PDF con Firma y Hash Criptográfico]
```

### 2.2. Arquitectura de Software
Sísifo adopta una **Arquitectura por Capas (Layered Architecture)** con principio **Local-First**:
* **Capa de Presentación:** Diseñada en Flutter con Material 3, garantizando interfaces claras, accesibles y libres de distracciones para el paciente y el terapeuta.
* **Capa de Gestión de Estado:** Implementada con el patrón `Provider` (`ChangeNotifier`), permitiendo reactividad limpia, trazabilidad y desacoplamiento entre pantallas e inferencias.
* **Capa de Lógica de Inferencia e Inteligencia Artificial:** Encapsulada en un agente multimodal dual:
  1. *Agente Local On-Device* (`LocalSisifoAgent`): Ejecuta la extracción de Unidades de Acción y la fusión multimodal directamente en el microprocesador del móvil sin requerir internet.
  2. *Agente Servidor FastAPI* (`agent_server/`): Servicio complementario para entornos que requieran validación cruzada o mayor capacidad de procesamiento.
* **Capa de Persistencia y Seguridad:** 
  * Almacenamiento local cifrado mediante **SQLCipher (AES-256)** a través de `DatabaseHelper`.
  * Sincronización asíncrona segura hacia **MongoDB Atlas** cuando existe conexión autorizada.

### 2.3. Diseño de Seguridad y Gobernanza de Datos
1. **Consentimiento Informado Expreso:** Módulo previo obligatorio que formaliza la autorización del paciente para el procesamiento biométrico conforme al marco normativo vigente.
2. **Bitácora de Auditoría Inmutable (Append-Only):** Cada creación de registro, edición de paciente o generación de informe genera una entrada de auditoría con identificador único UUID, sello de tiempo e integridad referencial, asegurando conformidad con la **NOM-004-SSA3-2012** (expediente clínico).
3. **No Retención Innecesaria de Biometría:** La fotografía puede procesarse en memoria volátil en local para extraer los vectores FACS y destruirse o almacenarse de forma estrictamente cifrada sin exposición a terceros.

---

## 3. Metodología

### 3.1. Metodología de Desarrollo
El proyecto se concibió bajo una metodología ágil adaptada a **Software as a Medical Device (SaMD)**, asegurando:
* Definición formal de casos de uso clínicos.
* Pruebas de consistencia algorítmica y mitigación de falsos negativos.
* Principios de *Privacy by Design* y *Security by Default*.

### 3.2. Metodología de Evaluación Multimodal

#### A. Componente Psicométrico (PHQ-9 Estandarizado)
Implementación basada en el instrumento validado de Kroenke, Spitzer y Williams (2001). Consta de 9 reactivos evaluados en escala Likert (0 a 3), arrojando un puntaje total de 0 a 27 estratificado en 5 categorías:
* `0 - 4`: Sin sintomatología / Mínima
* `5 - 9`: Leve
* `10 - 14`: Moderada
* `15 - 19`: Moderadamente Severa
* `20 - 27`: Severa

#### B. Componente de Biomarcadores Faciales (FACS - Facial Action Coding System)
Basado en los estudios de Paul Ekman y la literatura neuropsiquiátrica sobre mímica facial en la depresión, el agente analiza microexpresiones y actividad en regiones anatómicas clave:
* **AU1 (Inner Brow Raiser / Elevador frontal medial):** Asociado a tensión frontal, aflicción y tristeza contenida.
* **AU6 (Cheek Raiser / Elevador de mejilla):** Marcador indispensable de la expresión genuina de afecto positivo (Sonrisa de Duchenne).
* **AU12 (Lip Corner Puller / Cigomático mayor):** Marcador de elevación de comisuras labiales.
* **AU15 (Lip Corner Depressor / Depresor del ángulo de la boca):** Típicamente activo en tristeza prolongada y decaimiento emocional.

El algoritmo calcula la varianza de luminosidad y contraste textural en ventanas anatómicas delimitadas proporcionalmente (frente, mejillas, región peribucal).

#### C. Algoritmo de Fusión Multimodal y Detección de Discrepancias
A diferencia de sistemas que simplemente promedian puntajes, Sísifo implementa una **heurística clínica diferencial**:
* **Caso de Alerta por Discrepancia:** Si el paciente reporta un PHQ-9 "Bajo" o "Leve" (0–9), pero el análisis de biomarcadores faciales detecta anomalías significativas (ej. elevación simultánea de AU1 y AU15, con atenuación marcada de AU6 + AU12), el agente reclasifica el indicador a:
  * *Riesgo Moderado (Sugerido por Expresión Facial)*
  y emite una alerta al profesional sugiriendo una exploración clínica presencial exhaustiva.
* **Caso de Congruencia Severa:** Si ambos canales (cuestionario y expresión) reflejan niveles altos de aflicción, se eleva el índice de certeza algorítmica y se emite recomendación prioritaria de canalización inmediata.

---

## 4. Construcción del Prototipo

### 4.1. Ficha Técnica del Stack Tecnológico
* **Frontend Móvil:** Flutter (SDK Dart 3.3.0+), arquitectura multi-plataforma orientada a Android/iOS.
* **Enrutamiento:** `go_router` 14.x.
* **Gestor de Estado:** `provider` 6.x.
* **Cámara y Multimedia:** `camera` y paquete `image` para decodificación y segmentación de matrices de píxeles sin dependencias externas pesadas.
* **Base de Datos Local:** `sqflite_sqlcipher` (SQLite con cifrado transparente por llave criptográfica AES-256).
* **Base de Datos Remota:** `mongo_dart` con conexión TLS a clúster MongoDB Atlas.
* **Generación Documental:** `pdf` y `printing` para reportes clínicos con formato formal médico.
* **Backend de Respaldo:** Python 3.10+, FastAPI, Uvicorn, Pillow, NumPy.

### 4.2. Módulos Implementados en el Prototipo

1. **Módulo de Acceso y Gestión de Identidad:** Login autenticado para el terapeuta y gestión de sesiones.
2. **Módulo de Consentimiento Informado (`PrivacyConsentScreen`):** Verificación explícita de doble casilla (consentimiento del paciente informado y asunción de responsabilidad médica del psicólogo).
3. **Módulo de Captura Psicométrica (`Phq9Screen` y `QuestionCard`):** Presentación interactiva de las 9 preguntas con opciones estandarizadas y selector táctil ergonómico.
4. **Módulo de Captura Biométrica (`CameraScreen`):** Guía visual en pantalla para encuadre del rostro del paciente a distancia focal adecuada.
5. **Motor de Inferencia On-Device (`LocalSisifoAgent`):** Decodificación de imagen, extracción de Unidades de Acción FACS y evaluación de reglas clínicas con puntaje integrado `risk_score` (0.0 a 1.0).
6. **Módulo de Visualización y Diagnóstico (`ResultScreen` y `RiskBadge`):** Desglose pedagógico del resultado: severidad PHQ-9, estado facial, nivel de congruencia, observaciones del modelo y recomendación clínica.
7. **Módulo de Seguridad, Trazabilidad y Exportación (`AuditService` y `AuditPdfService`):** Inserción automática de eventos en la tabla `audit_logs` y exportación en un clic del informe clínico en formato PDF.

---

## 5. Creatividad y Originalidad

### 5.1. Fusión de Métricas Subjetivas y Objetivas
La mayoría de las herramientas existentes se polarizan en dos extremos: cuestionarios digitales básicos o complejos modelos de visión por computadora de laboratorio que descuidan la psicometría clínica estandarizada. Sísifo es original porque **integra ambos mundos en una sola matriz de decisión heurística**, tratando la discrepancia entre el habla y el gesto como un hallazgo clínico de alto valor.

### 5.2. Paradigma *Edge AI / Local-First* para Privacidad Médica
En un momento donde las soluciones de IA recurren indiscriminadamente a APIs en la nube de terceros exponiendo imágenes privadas, Sísifo implementó un **agente multimodal autónomo capaz de procesar la biometría 100% en el dispositivo**. La imagen facial no necesita salir del teléfono para ser interpretada; esto elimina vectores de ataque y cumple con los estándares éticos y legales más exigentes.

### 5.3. Enfoque Humano en el Ciclo (*Human-in-the-Loop*)
Sísifo evita la trampa del reduccionismo tecnológico: **no emite diagnósticos médicos automáticos ni receta tratamientos**. Su diseño se enfoca en empoderar al profesional con un indicador visual explicable (XAI - Explainable AI) que actúa como un segundo par de ojos objetivos.

### 5.4. Integración Normativa y Forense Nativa
A diferencia de proyectos académicos que ignoran el marco legal, Sísifo incluye desde su arquitectura fundacional el cumplimiento con normas de expediente clínico (NOM-004-SSA3-2012) y protección de datos sensibles mediante registros de auditoría *append-only* y bases de datos cifradas en reposo con SQLCipher.

---

## 6. Conclusión
El proyecto **Sísifo** representa una convergencia entre **salud mental, visión artificial aplicada y privacidad de datos**. Al resolver el sesgo del autorreporte tradicional mediante biomarcadores faciales procesados en el dispositivo, Sísifo se posiciona como un prototipo funcional, ético, escalable y con un impacto directo en la detección oportuna del riesgo de depresión.
