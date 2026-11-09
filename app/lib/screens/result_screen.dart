import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../utils/phq9_helper.dart';
import '../widgets/risk_badge.dart';

/// Pantalla de resultados de la evaluación clínica con desglose completo y por componentes
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final evaluation = provider.lastEvaluation;
    final theme = Theme.of(context);

    if (evaluation == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay resultados disponibles.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    }

    final scoreColor = getSeverityColor(evaluation.phq9Result.totalScore);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Resultado de Evaluación'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // SECCIÓN 1: RESULTADO GENERAL COMBINADO
            // ==========================================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      evaluation.patientName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(evaluation.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RiskBadge(
                      riskLevel: evaluation.riskLevel,
                      fontSize: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Perfil de Sintomatología: ${evaluation.phq9Severity}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Indicador de Apoyo Clínico: ${(evaluation.riskScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (evaluation.recommendation.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: Color(0xFF2E86AB), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Plan de Intervención Clínico',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E86AB)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              evaluation.recommendation,
                              style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Encabezado del desglose por separado
            Text(
              'Desglose por Componente',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ==========================================
            // SECCIÓN 2: DESGLOSE 1 - CUESTIONARIO PHQ-9
            // ==========================================
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment, color: Color(0xFF2E86AB)),
                            SizedBox(width: 8),
                            Text(
                              'Componente 1: Cuestionario PHQ-9',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                            '${evaluation.phq9Result.totalScore} / 27',
                            style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nivel de severidad sintomática: ${evaluation.phq9Severity}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Detalle de reactivos evaluados:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(9, (i) {
                      final answer = evaluation.phq9Result.answers[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E86AB)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _shortQuestion(i),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _answerColor(answer).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$answer',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _answerColor(answer),
                                  fontSize: 12,
                                ),
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
            const SizedBox(height: 16),

            // ==========================================
            // SECCIÓN 3: DESGLOSE 2 - ANÁLISIS FACIAL (FACS)
            // ==========================================
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.face_retouching_natural, color: Color(0xFF2E86AB)),
                        SizedBox(width: 8),
                        Text(
                          'Componente 2: Biomarcadores Faciales (FACS)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      evaluation.facialAnalysisNotes ?? 'No se detectaron notas faciales anormales.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                    ),
                    // Métricas AU ocultadas según requerimientos
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // AVISO CLÍNICO OBLIGATORIO (COFEPRIS SaMD / NOM-004)
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'AVISO CLÍNICO IMPORTANTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Este perfil de sintomatología es una herramienta de soporte a la decisión clínica '
                    'y NO constituye un diagnóstico clínico autónomo. El diagnóstico definitivo es '
                    'responsabilidad exclusiva del profesional de la salud mental tratante conforme a los '
                    'criterios diagnósticos DSM-5 / CIE-11 y la valoración integral del paciente.\n\n'
                    'Instrumento PHQ-9: © Pfizer Inc. Uso clínico libre de regalías con debida atribución.\n'
                    'Referencia: Kroenke K, Spitzer RL, Williams JBW. J Gen Intern Med. 2001;16(9):606-613.',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botón para volver al Dashboard
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.reset();
                  context.go('/dashboard');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Panel Principal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E86AB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _answerColor(int value) {
    switch (value) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange.shade600;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  String _shortQuestion(int index) {
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
