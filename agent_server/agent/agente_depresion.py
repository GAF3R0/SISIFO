class SistemaDepresionMultimodal:
    def __init__(self):
        # Reglas basadas en los baremos estandarizados del PHQ-9 (Kroenke et al., 2001)
        self._reglas_phq9 = [
            (4, "Mínima / Sin sintomatología", "Bajo", "Mantener hábitos saludables de autocuidado."),
            (9, "Leve", "Bajo-Moderado", "Monitoreo periódico y técnicas de psicoeducación/higiene del sueño."),
            (14, "Moderada", "Moderado", "Se sugieren técnicas cognitivo-conductuales y seguimiento profesional preventivo."),
            (19, "Moderadamente Severa", "Alto", "Recomendación de valoración clínica presencial prioritaria."),
            (27, "Severa", "Crítico / Alerta Clínica", "Canalización inmediata a servicios de salud mental y apoyo clínico especializado.")
        ]

    def evaluar_phq9(self, puntaje_phq9: int):
        if not (0 <= puntaje_phq9 <= 27):
            return "Puntaje inválido", "Desconocido", "Verificar entrada de datos."
        
        for limite, diag, nivel, rec in self._reglas_phq9:
            if puntaje_phq9 <= limite:
                return diag, nivel, rec

    def analizar_biomarcadores_faciales(self, au1: float, au6: float, au12: float, au15: float):
        anomalias = []
        if au1 > 0.6:
            anomalias.append("AU1")
        if au15 > 0.6:
            anomalias.append("AU15")
        if (au6 + au12) < 0.4:
            anomalias.append("Atenuación sonrisa")

        if len(anomalias) >= 2:
            return "Indicador Elevado", 0.88
        elif len(anomalias) == 1:
            return "Indicador Moderado", 0.70
        else:
            return "Sin Anomalías", 0.92

    def procesar_caso(self, id_usuario: str, phq9_score: int, au1: float, au6: float, au12: float, au15: float):
        categoria, riesgo, recomendacion = self.evaluar_phq9(phq9_score)
        estado_facial, certeza = self.analizar_biomarcadores_faciales(au1, au6, au12, au15)

        # Inferencia Multimodal de Soporte a la Decisión Clínica (COFEPRIS SaMD)
        # Caso 1: Posible minimización de síntomas con expresión facial sugerente
        if riesgo in ["Bajo", "Bajo-Moderado"] and estado_facial == "Indicador Elevado":
            riesgo = "Moderado (Sugerido por Expresión Facial)"
            recomendacion = "Se sugiere entrevista clínica presencial a profundidad; los biomarcadores faciales indican discrepancia con el autorreporte PHQ-9."
            certeza = certeza * 0.80

        # Caso 2: Coincidencia de autorreporte y biomarcadores
        elif riesgo in ["Alto", "Crítico / Alerta Clínica"] and estado_facial == "Indicador Elevado":
            certeza = min(certeza + 0.05, 1.0)
            recomendacion = f"[Hallazgo de apoyo clínico — congruencia multimodal elevada]: {recomendacion}"

        return {
            "ID Usuario": id_usuario,
            "PHQ-9 Score": phq9_score,
            "Nivel de Sintomatologia PHQ9": categoria,
            "Indicador de Riesgo PHQ9": riesgo,
            "Analisis Facial FACS": estado_facial,
            "Confianza del Modelo": f"{certeza * 100:.1f}%",
            "Recomendacion Clinica": recomendacion,
            "AUs": {
                "AU1": au1,
                "AU6": au6,
                "AU12": au12,
                "AU15": au15
            }
        }
