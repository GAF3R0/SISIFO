import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/evaluation.dart';
import '../utils/phq9_helper.dart';
import '../widgets/risk_badge.dart';

/// Modal o pantalla de detalle para que el psicólogo consulte el resultado completo
class EvaluationDetailModal extends StatelessWidget {
  final Evaluation evaluation;

  const EvaluationDetailModal({super.key, required this.evaluation});

  static void show(BuildContext context, Evaluation eval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvaluationDetailModal(evaluation: eval),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = getSeverityColor(evaluation.phq9Result.totalScore);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barra superior de agarre
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Encabezado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consulta de Evaluación',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E86AB),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Contenido con scroll
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Paciente y fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          evaluation.patientName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(evaluation.timestamp),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // SECCIÓN 1: RESULTADO GENERAL COMBINADO
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E86AB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2E86AB).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'DIAGNÓSTICO COMBINADO',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E86AB),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              RiskBadge(riskLevel: evaluation.riskLevel, fontSize: 12),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Severidad Global: ${evaluation.phq9Severity}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Puntaje de Riesgo IA Multimodal: ${(evaluation.riskScore * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                          if (evaluation.recommendation.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Recomendación Clínica:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              evaluation.recommendation,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // SECCIÓN 2: DESGLOSE POR SEPARADO
                    // ==========================================
                    Text(
                      'Desglose por Componente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Componente A: PHQ-9 (Cuestionario)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.assignment, color: Color(0xFF2E86AB), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      '1. Cuestionario PHQ-9',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '${evaluation.phq9Result.totalScore} / 27 pts',
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nivel según cuestionario: ${evaluation.phq9Severity}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Respuestas individuales:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(9, (i) {
                              final ans = evaluation.phq9Result.answers[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundColor: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                                      child: Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF2E86AB))),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getQuestionShortText(i),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      '$ans pt${ans == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: ans > 1 ? Colors.orange.shade800 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Componente B: Análisis Facial (FACS)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.face_retouching_natural, color: Color(0xFF2E86AB), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '2. Biomarcadores Faciales (FACS)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              evaluation.facialAnalysisNotes ?? 'No se registraron notas de biomarcadores.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                            ),
                            // Métricas AU ocultadas según requerimientos
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _getQuestionShortText(int index) {
    const shorts = [
      'Poco interés o placer',
      'Sentirse triste o sin esperanza',
      'Problemas de sueño',
      'Cansancio o poca energía',
      'Problemas de apetito',
      'Sentirse mal consigo mismo/a',
      'Dificultad para concentrarse',
      'Moverse muy lento o agitado/a',
      'Pensamientos de hacerse daño',
    ];
    return index < shorts.length ? shorts[index] : 'Pregunta ${index + 1}';
  }
}
