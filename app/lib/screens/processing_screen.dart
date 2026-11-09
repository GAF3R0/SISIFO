import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../services/auth_service.dart';

/// Pantalla de procesamiento — envía los datos al agente IA y espera respuesta
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animación de pulso mientras el agente procesa
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Iniciar envío al agente después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _submitEvaluation());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    final provider = context.read<AssessmentProvider>();
    final psychologistId =
        await AuthService.getCurrentPsychologistId() ?? 'unknown';

    final result = await provider.submitEvaluation(
      psychologistId: psychologistId,
    );

    if (!mounted) return;

    if (result != null) {
      // Éxito — navegar a resultados
      context.go('/result');
    } else {
      // Error — mostrar mensaje y volver
      _showError(provider.errorMessage ?? 'Error desconocido');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Error en el análisis'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('Volver al inicio'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitEvaluation(); // Reintentar
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono animado de pulso
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      size: 60,
                      color: Color(0xFF2E86AB),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Analizando evaluación...',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A5276),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'El agente está procesando el cuestionario PHQ-9\ny la imagen facial del paciente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Indicador de progreso lineal
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF2E86AB)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Esto puede tomar unos segundos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
