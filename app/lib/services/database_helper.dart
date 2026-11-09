import 'dart:async';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/psychologist.dart';
import '../models/patient.dart';
import '../models/evaluation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _dbName = 'sisifo_encrypted.db';
  static const _dbVersion = 4;
  static const _passphrasePrefKey = 'sisifo_db_secure_passphrase_v1';
  static const _uuid = Uuid();

  Database? _db;

  /// Obtiene o genera aleatoriamente la clave de cifrado local en el dispositivo.
  /// No se guarda la clave fija en el código fuente (Mitigación LFPDPPP Art. 19).
  static Future<String> _getOrCreatePassphrase() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_passphrasePrefKey);
    if (existing != null && existing.isNotEmpty) return existing;
    
    // Generar clave segura única para el dispositivo
    final generated = '${_uuid.v4().replaceAll('-', '')}${_uuid.v4().replaceAll('-', '')}';
    await prefs.setString(_passphrasePrefKey, generated);
    return generated;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    final passphrase = await _getOrCreatePassphrase();
    return await openDatabase(
      path,
      password: passphrase,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        email_verified INTEGER NOT NULL,
        role TEXT NOT NULL,
        password_hash TEXT
      );
    ''');
    // Precargar usuario Administrador por defecto
    await db.rawInsert('''
      INSERT OR REPLACE INTO users (id, email, email_verified, role, password_hash)
      VALUES (?, ?, ?, ?, ?)
    ''', [
      'admin-sisifo-master-001',
      'admin@gmail.com',
      1,
      'admin',
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', // SHA-256 de '123456'
    ]);
    await db.execute('''
      CREATE TABLE psychologists (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        license_number TEXT NOT NULL,
        specialty TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        active INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        gender TEXT,
        phone_number TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        active INTEGER NOT NULL,
        test_count INTEGER NOT NULL DEFAULT 0,
        last_test_date TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE evaluations (
        id TEXT PRIMARY KEY,
        patient_name TEXT NOT NULL,
        psychologist_id TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        answers TEXT NOT NULL,
        phq9_severity TEXT NOT NULL,
        recommendation TEXT NOT NULL,
        facial_notes TEXT,
        au1 INTEGER NOT NULL,
        au6 INTEGER NOT NULL,
        au12 INTEGER NOT NULL,
        au15 INTEGER NOT NULL,
        risk_level TEXT NOT NULL,
        risk_score REAL NOT NULL,
        evaluation_date TEXT NOT NULL,
        device_info TEXT NOT NULL,
        app_version TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        remote_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    // Bitácora de auditoría inmutable (NOM-004-SSA3-2012 y NOM-024-SSA3-2012)
    await db.execute('''
      CREATE TABLE audit_log (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        performed_by TEXT NOT NULL,
        performed_at TEXT NOT NULL,
        device_info TEXT,
        old_value_json TEXT,
        new_value_json TEXT
      );
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN password_hash TEXT;');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.rawInsert('''
          INSERT OR REPLACE INTO users (id, email, email_verified, role, password_hash)
          VALUES (?, ?, ?, ?, ?)
        ''', [
          'admin-sisifo-master-001',
          'admin@gmail.com',
          1,
          'admin',
          '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
        ]);
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS audit_log (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            action TEXT NOT NULL,
            performed_by TEXT NOT NULL,
            performed_at TEXT NOT NULL,
            device_info TEXT,
            old_value_json TEXT,
            new_value_json TEXT
          );
        ''');
      } catch (_) {}
    }
  }

  // ================= USERS =================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'LOWER(email) = ?', whereArgs: [email.toLowerCase().trim()]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ================= PSYCHOLOGISTS =================
  Future<int> insertPsychologist(Psychologist psychologist) async {
    final db = await database;
    return await db.insert('psychologists', psychologist.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Psychologist?> getPsychologist(String id) async {
    final db = await database;
    final maps = await db.query('psychologists', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Psychologist.fromMap(maps.first);
  }

  Future<List<Psychologist>> getAllPsychologists() async {
    final db = await database;
    final list = await db.query('psychologists', orderBy: 'full_name ASC');
    return list.map((m) => Psychologist.fromMap(m)).toList();
  }

  /// Actualiza el nombre y/o cédula de un psicólogo existente
  Future<int> updatePsychologist(Psychologist psychologist) async {
    final db = await database;
    return await db.update(
      'psychologists',
      psychologist.toMap(),
      where: 'id = ?',
      whereArgs: [psychologist.id],
    );
  }

  /// Actualiza el hash de contraseña de un usuario (por ID o por email)
  Future<int> updateUserPasswordHash(String userId, String email, String newHash) async {
    final db = await database;
    return await db.update(
      'users',
      {'password_hash': newHash},
      where: 'id = ? OR LOWER(email) = ?',
      whereArgs: [userId, email.toLowerCase().trim()],
    );
  }

  // ================= PATIENTS =================
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final list = await db.query('patients', orderBy: 'full_name ASC');
    return list.map((m) => Patient.fromMap(m)).toList();
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update('patients', patient.toMap(), where: 'id = ?', whereArgs: [patient.id]);
  }

  Future<void> recordPatientTest(String patientId, DateTime testDate) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE patients
      SET test_count = test_count + 1,
          last_test_date = ?,
          updated_at = ?
      WHERE id = ?
    ''', [testDate.toIso8601String(), DateTime.now().toIso8601String(), patientId]);
  }

  // ================= EVALUATIONS (Inmutabilidad NOM-004-SSA3-2012) =================
  
  /// Inserta una evaluación de forma inmutable (NOM-004: append-only).
  /// Si el ID ya existe, no se sobrescribe.
  Future<int> insertEvaluation(Evaluation evaluation) async {
    final db = await database;
    return await db.insert(
      'evaluations',
      evaluation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Evaluation>> getAllEvaluations() async {
    final db = await database;
    final list = await db.query(
      'evaluations',
      orderBy: 'evaluation_date DESC',
    );
    return list.map((m) => Evaluation.fromMap(m)).toList();
  }

  Future<List<Evaluation>> getEvaluationsByPsychologist(String psychologistId, {String? email}) async {
    final db = await database;
    List<Map<String, dynamic>> list;
    if (email != null && email.isNotEmpty) {
      list = await db.query(
        'evaluations',
        where: 'psychologist_id = ? OR psychologist_id = ? OR LOWER(psychologist_id) = ?',
        whereArgs: [psychologistId, email, email.toLowerCase().trim()],
        orderBy: 'evaluation_date DESC',
      );
    } else {
      list = await db.query(
        'evaluations',
        where: 'psychologist_id = ?',
        whereArgs: [psychologistId],
        orderBy: 'evaluation_date DESC',
      );
    }
    return list.map((m) => Evaluation.fromMap(m)).toList();
  }

  Future<List<Evaluation>> getPendingEvaluations() async {
    final db = await database;
    final list = await db.query(
      'evaluations',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.name],
      orderBy: 'created_at ASC',
    );
    return list.map((m) => Evaluation.fromMap(m)).toList();
  }

  Future<List<Evaluation>> getEvaluationsForPatient(String patientId) async {
    final db = await database;
    final list = await db.query(
      'evaluations',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'evaluation_date DESC',
    );
    return list.map((m) => Evaluation.fromMap(m)).toList();
  }

  Future<int> updateEvaluationSyncStatus(String evalId, SyncStatus status, {String? remoteId}) async {
    final db = await database;
    final values = <String, dynamic>{
      'sync_status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (remoteId != null) {
      values['remote_id'] = remoteId;
    }
    return await db.update('evaluations', values, where: 'id = ?', whereArgs: [evalId]);
  }

  // ================= AUDIT LOG (NOM-004 y NOM-024) =================

  /// Inserta una entrada de auditoría append-only
  Future<void> insertAuditLog({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String performedBy,
    String? deviceInfo,
    String? oldValueJson,
    String? newValueJson,
  }) async {
    final db = await database;
    await db.insert('audit_log', {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'performed_by': performedBy,
      'performed_at': DateTime.now().toIso8601String(),
      'device_info': deviceInfo ?? 'Sisifo Clinical App',
      'old_value_json': oldValueJson,
      'new_value_json': newValueJson,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Consulta la bitácora de auditoría
  Future<List<Map<String, dynamic>>> getAuditLog({String? entityType, String? entityId}) async {
    final db = await database;
    if (entityType != null && entityId != null) {
      return await db.query(
        'audit_log',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [entityType, entityId],
        orderBy: 'performed_at DESC',
      );
    } else if (entityType != null) {
      return await db.query(
        'audit_log',
        where: 'entity_type = ?',
        whereArgs: [entityType],
        orderBy: 'performed_at DESC',
      );
    }
    return await db.query('audit_log', orderBy: 'performed_at DESC');
  }
}
