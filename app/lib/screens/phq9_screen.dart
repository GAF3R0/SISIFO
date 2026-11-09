import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../utils/phq9_helper.dart';
import '../widgets/question_card.dart';

/// Pantalla del cuestionario PHQ-9
/// Presenta las 9 preguntas una por una con navegación de página en página
class Phq9Screen extends StatefulWidget {
  const Phq9Screen({super.key});

  @override
  State<Phq9Screen> createState() => _Phq9ScreenState();
}

class _Phq9ScreenState extends State<Phq9Screen> {
  final PageController _pageController = PageController();
  final TextEditingController _patientNameController = TextEditingController();
  int _currentPage = 0; // 0 = nombre del paciente, 1–9 = preguntas

  static const int _totalPages = 10; // 1 nombre + 9 preguntas

  @override
  void dispose() {
    _pageController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Última pregunta — ir a captura de foto
      context.push('/camera');
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool _canContinue(AssessmentProvider provider) {
    if (_currentPage == 0) {
      return _patientNameController.text.trim().isNotEmpty;
    }
    // Para preguntas 1–9, verificar que la respuesta fue seleccionada
    return provider.phq9Result.answers[_currentPage - 1] >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación PHQ-9'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevPage,
        ),
        actions: [
          // Puntaje en tiempo real (solo durante las preguntas)
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Puntaje: ${provider.phq9Result.totalScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progreso
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF2E86AB)),
            minHeight: 4,
          ),
          // Contenido paginado
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                // Página 0: Nombre del paciente
                _PatientNamePage(
                  controller: _patientNameController,
                  onChanged: (v) {
                    context.read<AssessmentProvider>().setPatientName(v);
                    setState(() {});
                  },
                ),
                // Páginas 1–9: Preguntas PHQ-9
                ...List.generate(9, (i) {
                  return SingleChildScrollView(
                    child: QuestionCard(
                      questionNumber: i + 1,
                      questionText: phq9Questions[i],
                      selectedValue: provider.phq9Result.answers[i],
                      onSelected: (value) {
                        context.read<AssessmentProvider>().setAnswer(i, value);
                        setState(() {});
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // Botón de continuar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue(provider) ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Tomar foto del rostro →'
                        : 'Continuar',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Página inicial para ingresar el nombre del paciente
class _PatientNamePage extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PatientNamePage({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.person_outline,
            size: 64,
            color: Color(0xFF2E86AB),
          ),
          const SizedBox(height: 24),
          Text(
            'Datos del paciente',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingrese el nombre o identificador del paciente antes de comenzar el cuestionario.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre o ID del paciente',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: 'Ej: Juan Pérez o PAC-001',
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El cuestionario PHQ-9 consta de 9 preguntas sobre las últimas 2 semanas.',
                    style: TextStyle(
                        color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Atribución legal: PHQ-9 © Pfizer Inc. Reproducido sin cargo conforme a su política de uso clínico.\n'
              'Kroenke K, Spitzer RL, Williams JBW. J Gen Intern Med. 2001;16(9):606-613.',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
