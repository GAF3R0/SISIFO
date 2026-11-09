# Modelos Pydantic para la API de Sisifo
# Define los esquemas de respuesta y validación de datos conforme a SaMD / COFEPRIS

from __future__ import annotations

from typing import Literal, Optional
from pydantic import BaseModel, Field


class EvaluationResponse(BaseModel):
    """
    Respuesta de la evaluación de apoyo a la decisión clínica.

    Incluye el nivel de severidad derivado del PHQ-9 y
    los biomarcadores de expresión facial (FACS).
    """

    risk_level: Literal["none", "mild", "moderate", "moderately_severe", "severe"] = Field(
        ...,
        description="Nivel de severidad sintomática estimada.",
        examples=["moderate"],
    )

    risk_score: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="Indicador continuo de apoyo clínico entre 0.0 (mínimo) y 1.0 (máximo).",
        examples=[0.6],
    )

    phq9_severity: str = Field(
        ...,
        description="Identificador interno de severidad PHQ-9.",
        examples=["moderate"],
    )

    phq9_severity_label: str = Field(
        ...,
        description="Etiqueta legible del nivel de sintomatología.",
        examples=["Moderada"],
    )

    recommendation: str = Field(
        ...,
        description="Sugerencia clínica orientativa de intervención.",
    )

    timestamp: str = Field(
        ...,
        description="Fecha y hora de la evaluación en formato ISO 8601 UTC.",
        examples=["2026-10-27T04:00:00Z"],
    )

    facial_analysis_notes: Optional[str] = Field(
        default=None,
        description=(
            "Notas de los biomarcadores faciales calculados on-device. "
            "Null cuando el análisis facial no está disponible."
        ),
    )

    algorithm_version: str = Field(
        default="SistemaDepresionMultimodal-v1.1",
        description="Versión del modelo de inferencia (Trazabilidad SaMD COFEPRIS).",
    )

    model_config = {
        "json_schema_extra": {
            "example": {
                "risk_level": "moderate",
                "risk_score": 0.6,
                "phq9_severity": "moderate",
                "phq9_severity_label": "Moderada",
                "recommendation": (
                    "Síntomas moderados. Se sugiere valoración clínica integral "
                    "y considerar intervención psicoterapéutica."
                ),
                "timestamp": "2026-10-27T04:00:00Z",
                "facial_analysis_notes": "Análisis expresión facial: Sin Anomalías (Confianza del modelo: 92.0%). Indicadores FACS: AU1=0.35, AU6=0.45, AU12=0.5, AU15=0.3",
                "algorithm_version": "SistemaDepresionMultimodal-v1.1",
            }
        }
    }
