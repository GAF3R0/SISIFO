// Modelo que representa el resultado del cuestionario PHQ-9
class Phq9Result {
  /// Lista de 9 respuestas, cada una con valor 0-3
  /// 0 = Nunca | 1 = Varios días | 2 = Más de la mitad | 3 = Casi todos los días
  final List<int> answers;

  const Phq9Result({required this.answers})
      : assert(answers.length == 9,
            'El PHQ-9 requiere exactamente 9 respuestas');

  /// Puntaje total del cuestionario (rango 0–27)
  int get totalScore => answers.fold(0, (sum, a) => sum + a);

  /// Etiqueta de severidad en español según el puntaje total
  String get severityLabel {
    final s = totalScore;
    if (s <= 4) return 'Sin depresión';
    if (s <= 9) return 'Leve';
    if (s <= 14) return 'Moderada';
    if (s <= 19) return 'Moderadamente severa';
    return 'Severa';
  }

  /// Nivel de riesgo en inglés para la API del agente
  String get riskLevel {
    final s = totalScore;
    if (s <= 4) return 'none';
    if (s <= 9) return 'mild';
    if (s <= 14) return 'moderate';
    if (s <= 19) return 'moderately_severe';
    return 'severe';
  }

  Map<String, dynamic> toJson() => {
        'answers': answers,
        'total_score': totalScore,
        'severity_label': severityLabel,
      };

  factory Phq9Result.fromJson(Map<String, dynamic> json) => Phq9Result(
        answers: List<int>.from(json['answers'] as List),
      );

  /// Resultado vacío (todas las respuestas en 0)
  factory Phq9Result.empty() => Phq9Result(answers: List.filled(9, 0));

  /// Copia del resultado con una respuesta modificada
  Phq9Result copyWithAnswer(int index, int value) {
    final newAnswers = List<int>.from(answers);
    newAnswers[index] = value;
    return Phq9Result(answers: newAnswers);
  }
}
