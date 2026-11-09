import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/psychologist.dart';
import '../models/evaluation.dart';

/// Clave donde se guarda la URI de MongoDB configurada por el administrador
const String kMongoUriPrefKey = 'mongo_atlas_uri';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  /// URI por defecto para el cluster de MongoDB Atlas del proyecto.
  /// Puede pasarse vía --dart-define=MONGO_URI=... o configurarse dentro de la aplicación (Ajustes de Servidor).
  static const String defaultUri = String.fromEnvironment(
    'MONGO_URI',
    defaultValue:
        'mongodb+srv://<USER>:<PASSWORD>@cluster.mongodb.net/sisifo?retryWrites=true&w=majority',
  );

  Db? _db;
  String? _currentUri;

  /// Devuelve la URI configurada desde SharedPreferences o la URI por defecto del cluster.
  static Future<String> getConfiguredUri() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(kMongoUriPrefKey);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return defaultUri;
  }

  /// Permite al administrador configurar una URI personalizada en runtime.
  static Future<void> setUri(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kMongoUriPrefKey, uri.trim());
    // Forzar reconexión con la nueva URI
    final instance = MongoDBService();
    await instance.close();
  }

  /// Restablece la URI a la predeterminada del sistema
  static Future<void> clearUri() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kMongoUriPrefKey);
    final instance = MongoDBService();
    await instance.close();
  }

  Future<Db> _getDb() async {
    final uri = await getConfiguredUri();
    if (_db != null && _db!.isConnected && _currentUri == uri) {
      return _db!;
    }
    // Si cambió la URI o no está conectado, cerrar la conexión anterior
    if (_db != null && _db!.isConnected) {
      await _db!.close();
    }
    _currentUri = uri;
    _db = await Db.create(uri.trim());
    await _db!.open();
    return _db!;
  }

  /// Prueba la conectividad con el cluster de MongoDB Atlas
  Future<bool> testConnection() async {
    try {
      final db = await _getDb();
      return db.isConnected;
    } catch (_) {
      return false;
    }
  }

  /// Cierra la conexión cuando ya no se use
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _db = null;
      _currentUri = null;
    }
  }

  // Colecciones (admitiendo nombres con o sin 's')
  Future<DbCollection> _getCollection(String primaryName, [String? alternateName]) async {
    final db = await _getDb();
    final names = await db.getCollectionNames();
    if (alternateName != null && names.contains(alternateName)) {
      return db.collection(alternateName);
    }
    if (names.contains(primaryName)) {
      return db.collection(primaryName);
    }
    return db.collection(primaryName);
  }

  /// Sube o actualiza un usuario en MongoDB (users)
  Future<void> upsertUser(Map<String, dynamic> userData) async {
    final coll = await _getCollection('users');
    final filter = where.eq('email', (userData['email'] as String).toLowerCase());
    await coll.replaceOne(filter, userData, upsert: true);
  }

  /// Busca un usuario por correo en MongoDB
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final coll = await _getCollection('users');
      final doc = await coll.findOne(where.eq('email', email.toLowerCase().trim()));
      return doc;
    } catch (_) {
      return null;
    }
  }

  /// Sube o actualiza un psicólogo en MongoDB (last_write_wins)
  Future<void> upsertPsychologist(Psychologist psycho) async {
    final coll = await _getCollection('psychologists', 'psychologits');
    final filter = where.eq('id', psycho.id);
    await coll.replaceOne(filter, psycho.toMongo(), upsert: true);
  }

  /// Actualiza contraseña de un usuario en MongoDB
  Future<void> updateUserPassword(String email, String newPasswordHash) async {
    try {
      final coll = await _getCollection('users');
      await coll.updateOne(
        where.eq('email', email.toLowerCase().trim()),
        modify.set('password_hash', newPasswordHash).set('updated_at', DateTime.now().toIso8601String()),
      );
    } catch (_) {}
  }

  /// Actualiza nombre y cédula de un psicólogo en MongoDB
  Future<void> updatePsychologistProfile(String id, String fullName, String licenseNumber, String specialty, {String? email}) async {
    try {
      final coll = await _getCollection('psychologists', 'psychologits');
      await coll.updateOne(
        where.eq('id', id),
        modify
            .set('fullName', fullName)
            .set('licenseNumber', licenseNumber)
            .set('specialty', specialty)
            .set('updatedAt', DateTime.now().toIso8601String()),
      );
      final usersColl = await _getCollection('users');
      final selector = email != null && email.isNotEmpty
          ? where.eq('id', id).or(where.eq('email', email.toLowerCase().trim()))
          : where.eq('id', id);
      await usersColl.updateOne(
        selector,
        modify.set('fullName', fullName).set('updated_at', DateTime.now().toIso8601String()),
      );
    } catch (_) {}
  }

  /// Sube o actualiza un paciente en MongoDB (last_write_wins)
  Future<void> upsertPatient(Patient patient) async {
    final coll = await _getCollection('patients');
    final filter = where.eq('id', patient.id);
    await coll.replaceOne(filter, patient.toMongo(), upsert: true);
  }

  /// Inserta una evaluación en MongoDB (append-only / inmutabilidad NOM-004-SSA3-2012).
  /// Si ya existe un documento con el mismo id, no lo sobrescribe.
  Future<String> upsertEvaluation(Evaluation evaluation) async {
    final coll = await _getCollection('evaluations', 'evaluation');
    final existing = await coll.findOne(where.eq('id', evaluation.id));
    if (existing == null) {
      final data = evaluation.toMongo();
      data['is_immutable'] = true;
      data['recorded_at'] = DateTime.now().toIso8601String();
      await coll.insert(data);
    }
    return evaluation.id;
  }

  /// Descarga todas las evaluaciones remotas desde MongoDB
  Future<List<Map<String, dynamic>>> getAllRemoteEvaluations() async {
    final coll = await _getCollection('evaluations', 'evaluation');
    return await coll.find(where.sortBy('evaluationDate', descending: true)).toList();
  }

  /// Descarga todos los pacientes remotos desde MongoDB
  Future<List<Map<String, dynamic>>> getAllRemotePatients() async {
    final coll = await _getCollection('patients');
    return await coll.find().toList();
  }

  /// Descarga todos los psicólogos remotos desde MongoDB
  Future<List<Map<String, dynamic>>> getAllRemotePsychologists() async {
    final coll = await _getCollection('psychologists', 'psychologits');
    return await coll.find().toList();
  }

  /// Descarga todos los usuarios remotos desde MongoDB
  Future<List<Map<String, dynamic>>> getAllRemoteUsers() async {
    try {
      final coll = await _getCollection('users');
      return await coll.find().toList();
    } catch (_) {
      return [];
    }
  }

  /// Descarga el historial remoto de un paciente
  Future<List<Map<String, dynamic>>> getRemotePatientEvaluations(String patientId) async {
    final coll = await _getCollection('evaluations', 'evaluation');
    final list = await coll.find(where.eq('patientId', patientId).sortBy('evaluationDate', descending: true)).toList();
    return list;
  }
}
