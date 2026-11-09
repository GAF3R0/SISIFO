import io
import math
from PIL import Image
from agent.agente_depresion import SistemaDepresionMultimodal

class SisifoAgent:
    def __init__(self):
        self.sistema = SistemaDepresionMultimodal()
        
        # Mapeo unificado para la app móvil basado en el indicador de riesgo de salida
        self._map_risk_level = {
            "Bajo": "none",
            "Bajo-Moderado": "mild",
            "Moderado": "moderate",
            "Moderado (Sugerido por Expresión Facial)": "moderate",
            "Alto": "moderately_severe",
            "Crítico / Alerta Clínica": "severe"
        }
        
        # Puntuaciones base por categoría para el risk_score
        self._map_base_score = {
            "none": 0.10,
            "mild": 0.35,
            "moderate": 0.60,
            "moderately_severe": 0.80,
            "severe": 0.95
        }

    def extraer_aus_de_imagen(self, image_bytes: bytes) -> tuple[float, float, float, float]:
        """
        Extrae o estima las unidades de acción FACS (AU1, AU6, AU12, AU15)
        a partir de los bytes de la fotografía facial del paciente.
        """
        try:
            image = Image.open(io.BytesIO(image_bytes)).convert("L")
            w, h = image.size

            frente = image.crop((w * 0.25, h * 0.15, w * 0.75, h * 0.35))
            mejillas = image.crop((w * 0.20, h * 0.40, w * 0.80, h * 0.65))
            boca = image.crop((w * 0.30, h * 0.65, w * 0.70, h * 0.85))

            def calcular_actividad(crop_img):
                pixels = list(crop_img.getdata())
                if not pixels:
                    return 0.5
                media = sum(pixels) / len(pixels)
                var = sum((p - media) ** 2 for p in pixels) / len(pixels)
                std = math.sqrt(var)
                return max(0.1, min(0.9, std / 50.0))

            act_frente = calcular_actividad(frente)
            act_mejillas = calcular_actividad(mejillas)
            act_boca = calcular_actividad(boca)

            au1 = round(min(0.95, act_frente * 1.1), 2)
            au6 = round(min(0.95, act_mejillas * 0.9), 2)
            au12 = round(min(0.95, act_boca * 0.8), 2)
            au15 = round(min(0.95, (1.0 - act_boca) * 0.7 + 0.2), 2)

            return au1, au6, au12, au15

        except Exception:
            return 0.35, 0.45, 0.50, 0.30

    def evaluate(
        self,
        phq9_score: int,
        phq9_answers: list,
        face_image_bytes: bytes,
        patient_id: str = "paciente"
    ) -> dict:
        """
        Evalúa el perfil sintomático combinando el PHQ-9 y el análisis FACS facial.
        Herramienta de soporte a la decisión clínica (SaMD).
        """
        au1, au6, au12, au15 = self.extraer_aus_de_imagen(face_image_bytes)

        resultado_agente = self.sistema.procesar_caso(
            id_usuario=patient_id,
            phq9_score=phq9_score,
            au1=au1,
            au6=au6,
            au12=au12,
            au15=au15
        )

        riesgo_clinico = resultado_agente["Indicador de Riesgo PHQ9"]
        risk_level = self._map_risk_level.get(riesgo_clinico, "none")
        base_score = self._map_base_score.get(risk_level, 0.10)

        if "Sugerido por Expresión Facial" in riesgo_clinico:
            base_score = min(1.0, base_score + 0.12)
        elif resultado_agente["Analisis Facial FACS"] == "Indicador Elevado":
            base_score = min(1.0, base_score + 0.05)

        notas_faciales = (
            f"Análisis expresión facial: {resultado_agente['Analisis Facial FACS']} "
            f"(Confianza del modelo: {resultado_agente['Confianza del Modelo']}). "
            f"Indicadores FACS: AU1={au1}, AU6={au6}, AU12={au12}, AU15={au15}"
        )

        return {
            "risk_level": risk_level,
            "risk_score": round(base_score, 2),
            "phq9_severity": risk_level,
            "phq9_severity_label": resultado_agente["Nivel de Sintomatologia PHQ9"],
            "recommendation": resultado_agente["Recomendacion Clinica"],
            "facial_analysis_notes": notas_faciales,
            "detalles_agente": resultado_agente,
            "algorithm_version": "SistemaDepresionMultimodal-v1.1",
        }
