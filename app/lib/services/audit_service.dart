import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

/// Servicio de bitácora de auditoría clínica (NOM-004-SSA3-2012 §4.3 y NOM-024-SSA3-2012).
/// Todas las operaciones son append-only.
class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  static const _uuid = Uuid();
  final _db = DatabaseHelper();

  /// Registra la creación de una evaluación clínica.
  Future<void> logEvaluationCreated({
    required String evaluationId,
    required String psychologistId,
    required Map<String, dynamic> evaluationData,
    String? deviceInfo,
  }) async {
    await _db.insertAuditLog(
      id: _uuid.v4(),
      entityType: 'evaluation',
      entityId: evaluationId,
      action: 'CREATE',
      performedBy: psychologistId,
      deviceInfo: deviceInfo,
      newValueJson: jsonEncode(evaluationData),
    );
  }

  /// Registra la creación o modificación de un paciente.
  Future<void> logPatientChange({
    required String patientId,
    required String psychologistId,
    required String action, // 'CREATE' | 'UPDATE'
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? deviceInfo,
  }) async {
    await _db.insertAuditLog(
      id: _uuid.v4(),
      entityType: 'patient',
      entityId: patientId,
      action: action,
      performedBy: psychologistId,
      deviceInfo: deviceInfo,
      oldValueJson: oldData != null ? jsonEncode(oldData) : null,
      newValueJson: newData != null ? jsonEncode(newData) : null,
    );
  }

  /// Registra un evento de autenticación (login/logout).
  Future<void> logAuthEvent({
    required String userId,
    required String action, // 'LOGIN' | 'LOGOUT' | 'PASSWORD_CHANGE'
    String? deviceInfo,
  }) async {
    await _db.insertAuditLog(
      id: _uuid.v4(),
      entityType: 'auth',
      entityId: userId,
      action: action,
      performedBy: userId,
      deviceInfo: deviceInfo,
    );
  }

  /// Registra intento de modificación de una evaluación (bloqueado por inmutabilidad NOM-004).
  Future<void> logImmutabilityViolationAttempt({
    required String evaluationId,
    required String psychologistId,
    String? deviceInfo,
  }) async {
    await _db.insertAuditLog(
      id: _uuid.v4(),
      entityType: 'evaluation',
      entityId: evaluationId,
      action: 'MODIFY_BLOCKED_NOM004',
      performedBy: psychologistId,
      deviceInfo: deviceInfo,
    );
  }

  /// Consulta entradas de auditoría
  Future<List<Map<String, dynamic>>> getLog({
    String? entityType,
    String? entityId,
  }) async {
    return await _db.getAuditLog(entityType: entityType, entityId: entityId);
  }
}
