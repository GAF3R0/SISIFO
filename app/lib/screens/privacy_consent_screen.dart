import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de Aviso de Privacidad y Consentimiento Expreso (LFPDPPP Art. 8, 9 y 16)
/// Previa a la realización de cualquier evaluación que involucre datos sensibles/biométricos.
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _patientConsentObtained = false;
  bool _psychologistResponsibility = false;
  bool _isLoading = false;

  Future<void> _proceed() async {
    if (!_patientConsentObtained || !_psychologistResponsibility) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_consent_timestamp',
        DateTime.now().toIso8601String(),
      );
      if (mounted) context.push('/phq9');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canProceed = _patientConsentObtained && _psychologistResponsibility;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Aviso de Privacidad y Consentimiento'),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined,
                            color: Color(0xFF2E86AB), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aviso de Privacidad Integral',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conforme a la LFPDPPP (DOF 05-07-2010), NOM-004-SSA3-2012 y NOM-024-SSA3-2012',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Texto del Aviso de Privacidad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('1. Responsable del Tratamiento'),
                    _body(
                      'El psicólogo clínico tratante debidamente autenticado en la plataforma '
                      'actúa como Responsable del tratamiento de los datos personales del paciente, '
                      'en términos del Art. 3, fracción XIV de la LFPDPPP.',
                    ),
                    _divider(),
                    _sectionTitle('2. Datos Personales Sensibles Recabados'),
                    _body(
                      '• Nombre o identificador único del paciente\n'
                      '• Fecha de nacimiento y datos demográficos clínicos\n'
                      '• Respuestas a la escala PHQ-9 (datos de salud mental)\n'
                      '• Imagen facial capturada temporalmente para inferencia de biomarcadores (dato biométrico)\n'
                      '• Unidades de acción facial numéricas (AU1, AU6, AU12, AU15)\n'
                      '• Indicadores de riesgo clínico y sugerencias de intervención',
                    ),
                    _divider(),
                    _sectionTitle('3. Procesamiento Biométrico'),
                    _body(
                      'La fotografía facial se utiliza con el único propósito de inferir unidades de acción (FACS). '
                      'El sistema no almacena imágenes faciales completas en su base de datos histórica persistente, '
                      'conservando únicamente los coeficientes matemáticos calculados.',
                    ),
                    _divider(),
                    _sectionTitle('4. Finalidad y Resguardo del Expediente'),
                    _body(
                      'Las finalidades consisten exclusivamente en servir de herramienta de soporte '
                      'a la decisión clínica y alimentar el expediente clínico conforme a la NOM-004-SSA3-2012. '
                      'Los registros cuentan con cifrado en reposo y garantía de inmutabilidad.',
                    ),
                    _divider(),
                    _sectionTitle('5. Derechos ARCO'),
                    _body(
                      'El titular de los datos o su representante puede ejercer sus derechos de '
                      'Acceso, Rectificación, Cancelación y Oposición acudiendo ante el profesional tratante.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Declaraciones de consentimiento
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Declaraciones del Profesional de la Salud',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A5276),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _patientConsentObtained,
                      onChanged: (v) =>
                          setState(() => _patientConsentObtained = v ?? false),
                      title: const Text(
                        'Cuento con el consentimiento expreso e informado del paciente '
                        '(o tutor) para el tratamiento de sus datos de salud y biométricos.',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF2E86AB),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _psychologistResponsibility,
                      onChanged: (v) =>
                          setState(() => _psychologistResponsibility = v ?? false),
                      title: const Text(
                        'Reconozco que el resultado es un instrumento de apoyo y no '
                        'sustituye mi juicio clínico ni el diagnóstico formal (COFEPRIS).',
                        style: TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF2E86AB),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (canProceed && !_isLoading) ? _proceed : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Confirmar y comenzar evaluación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E86AB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1A5276),
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1),
      );
}
