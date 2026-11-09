# Sisifo Agent Server

Servidor **FastAPI** que expone el agente de evaluación de riesgo de salud mental **Sisifo** como una API REST.

---

## Estructura del proyecto

```
agent_server/
├── main.py                # Aplicación FastAPI principal
├── requirements.txt       # Dependencias Python
├── .env.example           # Variables de entorno de ejemplo
├── agent/
│   ├── __init__.py
│   └── agent_core.py      # Clase SisifoAgent (mock → reemplazar con el real)
└── models/
    ├── __init__.py
    └── schemas.py         # Modelos Pydantic de respuesta
```

---

## Instalación

```bash
# 1. Crear entorno virtual
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
# .venv\Scripts\activate    # Windows

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env según el entorno
```

---

## Ejecución

```bash
# Modo desarrollo (recarga automática)
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Modo producción
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

---

## Documentación interactiva

Una vez corriendo, visitar:

- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:**       http://localhost:8000/redoc
- **OpenAPI JSON:** http://localhost:8000/openapi.json

---

## Endpoints

### `POST /evaluate`

Evalúa el riesgo de salud mental combinando el cuestionario PHQ-9 y una imagen facial.

| Campo            | Tipo         | Descripción                                    |
|------------------|--------------|------------------------------------------------|
| `phq9_score`     | `int`        | Puntaje total PHQ-9 (0–27)                     |
| `phq9_answers`   | `str` (JSON) | Array JSON con las 9 respuestas individuales   |
| `face_image`     | `file`       | Imagen facial del paciente (JPEG/PNG)          |
| `psychologist_id`| `str`        | ID del psicólogo (opcional)                    |

**Respuesta:**

```json
{
  "risk_level": "moderate",
  "risk_score": 0.6,
  "phq9_severity": "moderate",
  "phq9_severity_label": "Moderada",
  "recommendation": "Síntomas moderados. Se recomienda evaluación clínica...",
  "timestamp": "2026-10-27T04:00:00Z",
  "facial_analysis_notes": null
}
```

### `GET /health`

```json
{ "status": "ok" }
```

---

## Integrar el agente real

Para conectar el agente real de visión por computadora:

1. **Reemplazar** el contenido de `agent/agent_core.py` manteniendo la clase `SisifoAgent` y la firma del método `evaluate`:

   ```python
   def evaluate(
       self,
       phq9_score: int,
       phq9_answers: list[int],
       face_image_bytes: bytes,
   ) -> dict:
       ...
   ```

2. El `dict` retornado debe incluir las claves:
   - `risk_level` — `"none"` | `"mild"` | `"moderate"` | `"moderately_severe"` | `"severe"`
   - `risk_score` — `float` 0.0–1.0
   - `phq9_severity` — `str`
   - `recommendation` — `str`
   - `facial_analysis_notes` — `str | None`

3. Agregar las dependencias adicionales del agente real a `requirements.txt` (p. ej. `torch`, `opencv-python`, etc.).

4. Reiniciar el servidor — el `main.py` importará automáticamente la nueva implementación.

---

## Variables de entorno

| Variable     | Default     | Descripción                         |
|--------------|-------------|-------------------------------------|
| `HOST`       | `0.0.0.0`   | Dirección de escucha                |
| `PORT`       | `8000`      | Puerto del servidor                 |
| `DEBUG`      | `true`      | Habilita logs detallados            |
| `SECRET_KEY` | `changeme`  | Clave secreta (JWT) — cambiar en prod |
