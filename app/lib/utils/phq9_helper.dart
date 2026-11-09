import 'package:flutter/material.dart';

/// Las 9 preguntas oficiales del cuestionario PHQ-9 en español
const List<String> phq9Questions = [
  'Poco interés o placer en hacer las cosas',
  'Sentirse triste, deprimido/a o sin esperanza',
  'Dificultades para quedarse dormido/a, seguir dormido/a, o dormir demasiado',
  'Sentirse cansado/a o con poca energía',
  'Poco apetito o comer en exceso',
  'Sentirse mal consigo mismo/a, sentir que es un fracaso o que ha fallado a sí mismo/a o a su familia',
  'Dificultades para concentrarse en cosas tales como leer el periódico o ver televisión',
  'Moverse o hablar tan lento que otras personas pueden haberlo notado, o lo contrario — estar tan inquieto/a o agitado/a que se mueve mucho más de lo normal',
  'Pensamientos de que sería mejor estar muerto/a, o de hacerse algún daño',
];

/// Opciones de respuesta para cada pregunta PHQ-9
const List<String> phq9Options = [
  'Nunca',
  'Varios días',
  'Más de la mitad de los días',
  'Casi todos los días',
];

/// Retorna la etiqueta de severidad según el puntaje total PHQ-9
String getSeverityLabel(int score) {
  if (score <= 4) return 'Sin depresión';
  if (score <= 9) return 'Leve';
  if (score <= 14) return 'Moderada';
  if (score <= 19) return 'Moderadamente severa';
  return 'Severa';
}

/// Retorna el color asociado al nivel de severidad del puntaje PHQ-9
Color getSeverityColor(int score) {
  if (score <= 4) return const Color(0xFF4CAF50);  // Verde
  if (score <= 9) return const Color(0xFFFFEB3B);  // Amarillo
  if (score <= 14) return const Color(0xFFFF9800); // Naranja
  if (score <= 19) return const Color(0xFFE53935); // Rojo claro
  return const Color(0xFFB71C1C);                  // Rojo oscuro
}

/// Retorna el color por nivel de riesgo (string del agente)
Color getRiskColor(String riskLevel) {
  switch (riskLevel) {
    case 'none':
      return const Color(0xFF4CAF50);
    case 'mild':
      return const Color(0xFFFFEB3B);
    case 'moderate':
      return const Color(0xFFFF9800);
    case 'moderately_severe':
      return const Color(0xFFE53935);
    case 'severe':
      return const Color(0xFFB71C1C);
    default:
      return Colors.grey;
  }
}
