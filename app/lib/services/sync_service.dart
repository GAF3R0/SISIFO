import 'dart:io';
import 'database_helper.dart';
import 'mongodb_service.dart';
import '../models/user.dart';
import '../models/evaluation.dart';
import '../models/patient.dart';
import '../models/psychologist.dart';
import '../models/phq9_result.dart';

class SyncResult {
  final bool success;
  final int syncedCount;
  final int downloadedCount;
  final int failedCount;
  final String message;

  SyncResult({
    required this.success,
    required this.syncedCount,
    this.downloadedCount = 0,
    required this.failedCount,
    required this.message,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _localDb = DatabaseHelper();
  final MongoDBService _remoteDb = MongoDBService();

  /// Comprueba si hay conexión real a internet
  Future<bool> _hasInternetConnection() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ejecuta la sincronización bidireccional (Sube pendientes y baja datos de Atlas).
  Future<SyncResult> syncNow() async {
    // 1. Verificar conectividad básica
    final hasNet = await _hasInternetConnection();
    if (!hasNet) {
      return SyncResult(
        success: false,
        syncedCount: 0,
        downloadedCount: 0,
        failedCount: 0,
        message: 'Sin conexión a internet. Los datos se mantendrán seguros en el teléfono.',
      );
    }

    try {
      // 2. Probar conexión al cluster
      final isConnected = await _remoteDb.testConnection();
      if (!isConnected) {
        return SyncResult(
          success: false,
          syncedCount: 0,
          downloadedCount: 0,
          failedCount: 0,
          message: 'No se pudo conectar a MongoDB Atlas. Verifique la IP en Network Access.',
        );
      }

      // ==========================================
      // A. SUBIDA: Enviar datos locales a MongoDB
      // ==========================================

      // Sincronizar todos los pacientes locales
      final allPatients = await _localDb.getAllPatients();
      for (final patient in allPatients) {
        try {
          await _remoteDb.upsertPatient(patient);
        } catch (_) {}
      }

      // Sincronizar evaluaciones pendientes
      final pendingEvaluations = await _localDb.getPendingEvaluations();
      int synced = 0;
      int failed = 0;

      for (final eval in pendingEvaluations) {
        try {
          final remoteId = await _remoteDb.upsertEvaluation(eval);
          await _localDb.updateEvaluationSyncStatus(
            eval.id,
            SyncStatus.synced,
            remoteId: remoteId,
          );
          synced++;
        } catch (e) {
          await _localDb.updateEvaluationSyncStatus(
            eval.id,
            SyncStatus.failed,
          );
          failed++;
        }
      }

      // ==========================================
      // B. BAJADA: Descargar datos de MongoDB Atlas
      // ==========================================
      int downloaded = 0;

      // 0. Descargar usuarios de MongoDB y sincronizar a SQLite
      try {
        final remoteUsers = await _remoteDb.getAllRemoteUsers();
        for (final doc in remoteUsers) {
          try {
            final uId = (doc['id'] ?? doc['_id']?.toString() ?? '') as String;
            final uEmail = (doc['email'] ?? '') as String;
            final uHash = (doc['password_hash'] ?? doc['passwordHash']) as String?;
            final uRole = (doc['role'] == 'admin') ? UserRole.admin : UserRole.psychologist;
            if (uId.isNotEmpty && uEmail.isNotEmpty) {
              await _localDb.insertUser(User(
                id: uId,
                email: uEmail,
                emailVerified: true,
                role: uRole,
                passwordHash: uHash,
              ));
            }
          } catch (_) {}
        }
      } catch (_) {}

      // 1. Descargar psicólogos de MongoDB
      try {
        final remotePsychos = await _remoteDb.getAllRemotePsychologists();
        for (final doc in remotePsychos) {
          try {
            final psycho = Psychologist.fromMongo(doc);
            await _localDb.insertPsychologist(psycho);
          } catch (_) {}
        }
      } catch (_) {}

      // 2. Descargar pacientes de MongoDB
      try {
        final remotePatients = await _remoteDb.getAllRemotePatients();
        for (final doc in remotePatients) {
          try {
            final patient = Patient.fromMongo(doc);
            await _localDb.insertPatient(patient);
          } catch (_) {}
        }
      } catch (_) {}

      // 3. Descargar evaluaciones de MongoDB
      try {
        final remoteEvals = await _remoteDb.getAllRemoteEvaluations();
        for (final doc in remoteEvals) {
          try {
            final answers = (doc['answers'] as List<dynamic>?)
                    ?.map((e) => (e as num).toInt())
                    .toList() ??
                List.filled(9, 0);

            final evalId = (doc['id'] ?? doc['_id']?.toString() ?? '') as String;
            final eval = Evaluation(
              id: evalId,
              patientName: doc['patientName'] ?? 'Paciente',
              psychologistId: doc['psychologistId'] ?? '',
              patientId: doc['patientId'] ?? '',
              phq9Result: Phq9Result(answers: answers),
              phq9Severity: doc['phq9Severity'] ?? '',
              recommendation: doc['recommendation'] ?? '',
              facialAnalysisNotes: (doc['facialAnalysisNotes'] ?? doc['facialNotes']) as String?,
              au1: (doc['au1'] as num?)?.toInt() ?? 0,
              au6: (doc['au6'] as num?)?.toInt() ?? 0,
              au12: (doc['au12'] as num?)?.toInt() ?? 0,
              au15: (doc['au15'] as num?)?.toInt() ?? 0,
              riskLevel: doc['riskLevel'] ?? 'none',
              riskScore: (doc['riskScore'] as num?)?.toDouble() ?? 0.0,
              timestamp: doc['evaluationDate'] != null
                  ? DateTime.tryParse(doc['evaluationDate'].toString()) ?? DateTime.now()
                  : DateTime.now(),
              syncStatus: SyncStatus.synced,
              remoteId: evalId,
            );
            await _localDb.insertEvaluation(eval);
            downloaded++;
          } catch (_) {}
        }
      } catch (_) {}

      final message = 'Sincronización exitosa: $synced subidas, $downloaded descargadas desde Atlas.';

      return SyncResult(
        success: failed == 0,
        syncedCount: synced,
        downloadedCount: downloaded,
        failedCount: failed,
        message: message,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        syncedCount: 0,
        downloadedCount: 0,
        failedCount: 0,
        message: 'Error durante la sincronización: $e',
      );
    }
  }
}
