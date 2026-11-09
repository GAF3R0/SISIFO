# Servidor FastAPI — Sisifo Agent Server
# Inferencia multimodal como Software as a Medical Device (SaMD) de apoyo clínico

from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import json
import logging
import datetime
import os

from pydantic import BaseModel
from models.schemas import EvaluationResponse

class DatosEvaluacion(BaseModel):
    id_usuario: str
    phq9_score: int
    au1: float
    au6: float
    au12: float
    au15: float

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("sisifo_server")

try:
    from agent.agent_core import SisifoAgent
    logger.info("Agente real SisifoAgent cargado correctamente.")
except ImportError:
    logger.warning("No se encontró agent.agent_core. Usando agente mock para desarrollo.")

    class SisifoAgent:  # type: ignore[no-redef]
        def evaluate(
            self,
            phq9_score: int,
            phq9_answers: list,
            face_image_bytes: bytes,
            patient_id: str = "paciente"
        ) -> dict:
            return {
                "risk_level": "none",
                "risk_score": 0.0,
                "phq9_severity": "minimal",
                "phq9_severity_label": "Mínima",
                "recommendation": "Mock de desarrollo.",
                "facial_analysis_notes": None,
                "algorithm_version": "SistemaDepresionMultimodal-v1.1",
            }

agent_instance: SisifoAgent | None = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global agent_instance
    logger.info("Iniciando servidor Sisifo…")
    agent_instance = SisifoAgent()
    yield
    logger.info("Servidor Sisifo detenido.")

app = FastAPI(
    title="Sisifo Agent Server",
    description="API de inferencia para soporte a la decisión clínica en salud mental.",
    version="1.1.0",
    lifespan=lifespan,
)

# ---------------------------------------------------------------------------
# CORS — Restricción de orígenes autorizados
# ---------------------------------------------------------------------------
_raw_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:8000,http://127.0.0.1:8000")
_allowed_origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

@app.get("/health", summary="Verificación de salud del servidor")
async def health() -> dict:
    return {"status": "ok", "version": "1.1.0"}

@app.post("/evaluar", summary="Evaluación directa con AUs (FACS)")
def evaluar_paciente(datos: DatosEvaluacion):
    if agent_instance is None:
        raise HTTPException(status_code=500, detail="El agente no está inicializado.")
    return agent_instance.sistema.procesar_caso(
        datos.id_usuario,
        datos.phq9_score,
        datos.au1,
        datos.au6,
        datos.au12,
        datos.au15
    )

@app.post(
    "/evaluate",
    response_model=EvaluationResponse,
    summary="Evaluar perfil clínico y biomarcadores",
)
async def evaluate(
    phq9_score: int = Form(..., description="Puntaje total del PHQ-9 (0–27)"),
    phq9_answers: str = Form(
        ..., description="JSON array con las 9 respuestas individuales del PHQ-9"
    ),
    face_image: UploadFile = File(..., description="Imagen facial del paciente para inferencia on-device/servidor"),
    psychologist_id: str = Form(
        default="", description="ID del psicólogo tratante"
    ),
) -> EvaluationResponse:
    if not (0 <= phq9_score <= 27):
        raise HTTPException(
            status_code=422,
            detail="phq9_score debe estar entre 0 y 27.",
        )

    try:
        answers: list = json.loads(phq9_answers)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=422,
            detail="phq9_answers debe ser un JSON array válido.",
        )

    try:
        image_bytes: bytes = await face_image.read()
    except Exception as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Error al leer la imagen: {exc}",
        )

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="La imagen facial no puede estar vacía.",
        )

    logger.info(
        "Evaluación recibida | phq9_score=%d | psicólogo=%s | imagen=%s bytes",
        phq9_score,
        psychologist_id or "N/A",
        len(image_bytes),
    )

    try:
        result: dict = agent_instance.evaluate(
            phq9_score=phq9_score,
            phq9_answers=answers,
            face_image_bytes=image_bytes,
        )
    except Exception as exc:
        logger.error("Error en el agente: %s", exc, exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error interno del agente: {exc}",
        )

    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()

    return EvaluationResponse(
        risk_level=result["risk_level"],
        risk_score=result["risk_score"],
        phq9_severity=result["phq9_severity"],
        phq9_severity_label=result.get("phq9_severity_label", result["phq9_severity"].capitalize()),
        recommendation=result["recommendation"],
        timestamp=timestamp,
        facial_analysis_notes=result.get("facial_analysis_notes"),
        algorithm_version=result.get("algorithm_version", "SistemaDepresionMultimodal-v1.1"),
    )
