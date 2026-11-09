import 'package:flutter/material.dart';
import '../models/phq9_result.dart';
import '../models/evaluation.dart';
import '../models/patient.dart';
import '../services/local_agent_service.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';
import '../services/audit_service.dart';

/// Provider principal que gestiona el estado de una evaluación en curso (100% on-device)
class AssessmentProvider extends ChangeNotifier {
  Phq9Result _phq9Result = Phq9Result.empty();
  String _patientName = '';
  String? _imagePath;
  bool _isLoading = false;
  String? _errorMessage;
  Evaluation? _lastEvaluation;

  AssessmentProvider();

  // ── Getters ──────────────────────────────────────────────────────────────

  Phq9Result get phq9Result => _phq9Result;
  String get patientName => _patientName;
  String? get imagePath => _imagePath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Evaluation? get lastEvaluation => _lastEvaluation;

  /// True si todas las 9 preguntas fueron respondidas
  bool get isPhq9Complete =>
      _phq9Result.answers.every((a) => a >= 0 && a <= 3);

  /// True si la imagen del rostro fue capturada
  bool get hasImage => _imagePath != null && _imagePath!.isNotEmpty;

  /// True si la evaluación está lista para procesarse
  bool get isReadyToSubmit =>
      _patientName.isNotEmpty && isPhq9Complete && hasImage;

  // ── Setters ──────────────────────────────────────────────────────────────

  void setAnswer(int index, int value) {
    _phq9Result = _phq9Result.copyWithAnswer(index, value);
    notifyListeners();
  }

  void setPatientName(String name) {
    _patientName = name;
    notifyListeners();
  }

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  /// Ejecuta la evaluación multimodal directamente en el dispositivo (sin servidor)
  Future<Evaluation?> submitEvaluation({
    required String psychologistId,
  }) async {
    if (!isReadyToSubmit) {
      _errorMessage = 'Faltan datos para completar la evaluación.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Breve pausa para transicionar fluidamente en la UI
      await Future.delayed(const Duration(milliseconds: 600));

      // Inferencia 100% local on-device
      final result = LocalSisifoAgent.evaluate(
        phq9Score: _phq9Result.totalScore,
        phq9Answers: _phq9Result.answers,
        imagePath: _imagePath!,
        psychologistId: psychologistId,
      );

      final aus = (result['aus'] as Map<String, dynamic>?) ?? {};

      _lastEvaluation = Evaluation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientName: _patientName,
        phq9Result: _phq9Result,
        riskLevel: result['risk_level'] as String,
        riskScore: (result['risk_score'] as num).toDouble(),
        phq9Severity: result['phq9_severity'] as String? ?? _phq9Result.severityLabel,
        recommendation: result['recommendation'] as String? ?? '',
        facialAnalysisNotes: result['facial_analysis_notes'] as String?,
        psychologistId: psychologistId,
        au1: ((aus['au1'] as num?)?.toDouble() ?? 0.0 * 100).round(),
        au6: ((aus['au6'] as num?)?.toDouble() ?? 0.0 * 100).round(),
        au12: ((aus['au12'] as num?)?.toDouble() ?? 0.0 * 100).round(),
        au15: ((aus['au15'] as num?)?.toDouble() ?? 0.0 * 100).round(),
        syncStatus: SyncStatus.pending,
      );

      // Guardar en SQLite local cifrado
      try {
        final db = DatabaseHelper();
        await db.insertEvaluation(_lastEvaluation!);

        // Bitácora de auditoría inmutable (NOM-004-SSA3-2012)
        AuditService().logEvaluationCreated(
          evaluationId: _lastEvaluation!.id,
          psychologistId: psychologistId,
          evaluationData: _lastEvaluation!.toMap(),
        ).catchError((_) {});

        // Registrar o actualizar paciente
        final patient = await db.getPatient(_lastEvaluation!.patientId);
        if (patient == null) {
          await db.insertPatient(Patient(
            id: _lastEvaluation!.patientId,
            fullName: _patientName,
            dateOfBirth: DateTime(2000, 1, 1),
            testCount: 1,
            lastTestDate: DateTime.now(),
          ));
        } else {
          await db.recordPatientTest(_lastEvaluation!.patientId, DateTime.now());
        }
      } catch (dbErr) {
        debugPrint('Error guardando en BD local: $dbErr');
      }

      // Sincronización automática a Atlas en background si está configurado
      SyncService().syncNow().then((syncRes) {
        debugPrint('Auto-sync: ${syncRes.message}');
      }).catchError((e) {
        debugPrint('Auto-sync error: $e');
      });

      return _lastEvaluation;
    } catch (e) {
      _errorMessage = 'Error en el procesamiento local: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reinicia el estado para una nueva evaluación
  void reset() {
    _phq9Result = Phq9Result.empty();
    _patientName = '';
    _imagePath = null;
    _isLoading = false;
    _errorMessage = null;
    _lastEvaluation = null;
    notifyListeners();
  }
}
