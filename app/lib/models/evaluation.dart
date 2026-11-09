import 'dart:convert';
import 'phq9_result.dart';

enum SyncStatus { pending, synced, failed }

class Evaluation {
  final String id;
  final String patientName;
  final String patientId;
  final String psychologistId;
  final Phq9Result phq9Result;
  final String riskLevel;
  final double riskScore;
  final String phq9Severity;
  final String recommendation;
  final String? facialAnalysisNotes;
  final DateTime timestamp;
  
  // AU & Device metrics
  final int au1;
  final int au6;
  final int au12;
  final int au15;
  final String deviceInfo;
  final String appVersion;
  final SyncStatus syncStatus;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Evaluation({
    required this.id,
    required this.patientName,
    String? patientId,
    required this.psychologistId,
    required this.phq9Result,
    required this.riskLevel,
    required this.riskScore,
    String? phq9Severity,
    this.recommendation = '',
    this.facialAnalysisNotes,
    DateTime? timestamp,
    this.au1 = 0,
    this.au6 = 0,
    this.au12 = 0,
    this.au15 = 0,
    this.deviceInfo = 'Android/Flutter',
    this.appVersion = '1.0.0',
    this.syncStatus = SyncStatus.pending,
    this.remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : patientId = patientId ?? patientName,
        phq9Severity = phq9Severity ?? phq9Result.severityLabel,
        timestamp = timestamp ?? DateTime.now(),
        createdAt = createdAt ?? timestamp ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_id': patientId,
      'psychologist_id': psychologistId,
      'answers': jsonEncode(phq9Result.answers),
      'risk_level': riskLevel,
      'risk_score': riskScore,
      'phq9_severity': phq9Severity,
      'recommendation': recommendation,
      'facial_notes': facialAnalysisNotes,
      'au1': au1,
      'au6': au6,
      'au12': au12,
      'au15': au15,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'sync_status': syncStatus.name,
      'remote_id': remoteId,
      'evaluation_date': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Evaluation.fromMap(Map<String, dynamic> map) {
    List<int> answers = List.filled(9, 0);
    if (map['answers'] is String) {
      try {
        final decoded = jsonDecode(map['answers'] as String);
        if (decoded is List) {
          answers = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    } else if (map['answers'] is List) {
      answers = (map['answers'] as List).map((e) => (e as num).toInt()).toList();
    }

    SyncStatus parseStatus(dynamic val) {
      if (val == 'synced') return SyncStatus.synced;
      if (val == 'failed') return SyncStatus.failed;
      return SyncStatus.pending;
    }

    final date = map['evaluation_date'] != null
        ? DateTime.parse(map['evaluation_date'].toString())
        : (map['timestamp'] != null
            ? (map['timestamp'] is DateTime ? map['timestamp'] : DateTime.parse(map['timestamp'].toString()))
            : DateTime.now());

    return Evaluation(
      id: map['id'] as String,
      patientName: (map['patient_name'] ?? map['patientName'] ?? 'Paciente') as String,
      patientId: (map['patient_id'] ?? map['patientId'] ?? '') as String,
      psychologistId: (map['psychologist_id'] ?? map['psychologistId'] ?? '') as String,
      phq9Result: Phq9Result(answers: answers.length == 9 ? answers : List.filled(9, 0)),
      riskLevel: (map['risk_level'] ?? map['riskLevel'] ?? 'Bajo') as String,
      riskScore: (map['risk_score'] != null)
          ? (map['risk_score'] as num).toDouble()
          : ((map['riskScore'] != null) ? (map['riskScore'] as num).toDouble() : 0.0),
      phq9Severity: (map['phq9_severity'] ?? map['phq9Severity'] ?? '') as String,
      recommendation: (map['recommendation'] ?? '') as String,
      facialAnalysisNotes: (map['facial_notes'] ?? map['facialAnalysisNotes']) as String?,
      timestamp: date,
      au1: (map['au1'] ?? 0) as int,
      au6: (map['au6'] ?? 0) as int,
      au12: (map['au12'] ?? 0) as int,
      au15: (map['au15'] ?? 0) as int,
      deviceInfo: (map['device_info'] ?? map['deviceInfo'] ?? 'Android/Flutter') as String,
      appVersion: (map['app_version'] ?? map['appVersion'] ?? '1.0.0') as String,
      syncStatus: parseStatus(map['sync_status'] ?? map['syncStatus']),
      remoteId: (map['remote_id'] ?? map['remoteId']) as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : date,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : date,
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      'id': id,
      'patientName': patientName,
      'patientId': patientId,
      'psychologistId': psychologistId,
      'answers': phq9Result.answers,
      'totalScore': phq9Result.totalScore,
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'phq9Severity': phq9Severity,
      'recommendation': recommendation,
      'facialAnalysisNotes': facialAnalysisNotes,
      'au1': au1,
      'au6': au6,
      'au12': au12,
      'au15': au15,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'syncStatus': 'synced',
      'evaluationDate': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation.fromMap(json);
}
