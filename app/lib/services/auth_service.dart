import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/psychologist.dart';
import 'database_helper.dart';
import 'mongodb_service.dart';
import 'sync_service.dart';
import 'audit_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Servicio de autenticación con validación de credenciales, hash SHA-256
/// y soporte para roles (Psicólogo / Admin) local y MongoDB Atlas.
class AuthService {
  static const String _keyEmail = 'auth_email';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyRole = 'auth_role';
  static const String _defaultAdminHash =
      '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92';

  static final DatabaseHelper _localDb = DatabaseHelper();
  static final MongoDBService _remoteDb = MongoDBService();
  static const Uuid _uuid = Uuid();

  /// Genera hash SHA-256 para contraseñas
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Inicialización general de autenticación
  static Future<void> initialize() async {}

  /// Inicia sesión con Email y Contraseña comprobando hash local o remoto en Atlas.
  static Future<bool> login(String rawEmail, String password) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthException('Por favor, ingresa un correo electrónico válido');
    }
    if (password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres');
    }

    final pHash = hashPassword(password);

    // 1. Intentar validar en la base de datos local
    User? localUser = await _localDb.getUserByEmail(email);

    // Asegurar que si es el admin por defecto y no existe aún localmente se inserte
    if (localUser == null && email == 'admin@gmail.com') {
      localUser = User(
        id: 'admin-sisifo-master-001',
        email: 'admin@gmail.com',
        emailVerified: true,
        role: UserRole.admin,
        passwordHash: hashPassword('123456'),
      );
      await _localDb.insertUser(localUser);
    }

    // 2. Si no está local o su hash no coincide, consultar MongoDB Atlas si está configurado
    Map<String, dynamic>? remoteUser;
    if (localUser == null || (localUser.passwordHash != null && localUser.passwordHash!.isNotEmpty && localUser.passwordHash != pHash)) {
      try {
        remoteUser = await _remoteDb.findUserByEmail(email);
      } catch (_) {}
    }

    String userId;
    UserRole role = UserRole.psychologist;

    if (remoteUser != null) {
      final remoteHash = (remoteUser['password_hash'] ?? remoteUser['passwordHash']) as String?;
      if (remoteHash != null && remoteHash.isNotEmpty && remoteHash != pHash) {
        throw const AuthException('Contraseña incorrecta');
      }
      userId = (remoteUser['id'] ?? remoteUser['_id']?.toString() ?? _uuid.v4()) as String;
      final roleStr = remoteUser['role'] as String?;
      role = (roleStr == 'admin') ? UserRole.admin : UserRole.psychologist;

      // Sincronizar usuario descargado a local
      localUser = User(
        id: userId,
        email: email,
        emailVerified: true,
        role: role,
        passwordHash: remoteHash ?? pHash,
      );
      await _localDb.insertUser(localUser);
    } else if (localUser != null) {
      // Validar hash si está guardado en local
      if (localUser.passwordHash != null && localUser.passwordHash!.isNotEmpty && localUser.passwordHash != pHash) {
        throw const AuthException('Contraseña incorrecta');
      }
      userId = localUser.id;
      role = localUser.role;
    } else {
      // No existe ni en local ni en MongoDB
      throw const AuthException('No existe ninguna cuenta registrada con este correo');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role.name);

    // Advertencia de cambio de contraseña por defecto para admin (Seguridad LFPDPPP)
    final mustChange = (role == UserRole.admin && pHash == _defaultAdminHash);
    await prefs.setBool('must_change_password', mustChange);

    // Si es psicólogo, asegurar registro local y remoto
    if (role == UserRole.psychologist) {
      final existingPsycho = await _localDb.getPsychologist(userId);
      if (existingPsycho == null) {
        final psychologist = Psychologist(
          id: userId,
          fullName: email.split('@').first,
          email: email,
          licenseNumber: '',
          specialty: 'Psicología Clínica',
        );
        await _localDb.insertPsychologist(psychologist);
        _remoteDb.upsertPsychologist(psychologist).catchError((_) {});
      }
    }

    // Bitácora de auditoría (NOM-004)
    AuditService().logAuthEvent(userId: userId, action: 'LOGIN').catchError((_) {});

    return true;
  }

  /// Registro de nuevo psicólogo o admin con verificación de correo duplicado.
  static Future<void> register({
    required String rawEmail,
    required String password,
    required String fullName,
    String licenseNumber = '',
    String specialty = 'Psicología Clínica',
    UserRole role = UserRole.psychologist,
    bool loginAfterRegister = false,
  }) async {
    final email = rawEmail.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      throw const AuthException('Correo electrónico inválido');
    }
    if (password.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres');
    }

    // Verificar si ya existe en local
    final existingLocal = await _localDb.getUserByEmail(email);
    if (existingLocal != null) {
      throw const AuthException('Ya existe un usuario registrado con este correo');
    }

    // Verificar si ya existe en MongoDB
    try {
      final existingRemote = await _remoteDb.findUserByEmail(email);
      if (existingRemote != null) {
        throw const AuthException('Ya existe un usuario registrado con este correo en el servidor');
      }
    } catch (_) {}

    final userId = _uuid.v4();
    final pHash = hashPassword(password);

    final user = User(
      id: userId,
      email: email,
      emailVerified: false,
      role: role,
      passwordHash: pHash,
    );
    await _localDb.insertUser(user);

    // Guardar en MongoDB con hash
    try {
      await _remoteDb.upsertUser({
        'id': userId,
        'email': email,
        'fullName': fullName,
        'role': role.name,
        'email_verified': false,
        'password_hash': pHash,
        'licenseNumber': licenseNumber,
        'specialty': specialty,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'active': true,
      });
    } catch (_) {}

    if (role == UserRole.psychologist) {
      final psychologist = Psychologist(
        id: userId,
        fullName: fullName,
        email: email,
        licenseNumber: licenseNumber,
        specialty: specialty,
      );
      await _localDb.insertPsychologist(psychologist);
      try {
        await _remoteDb.upsertPsychologist(psychologist);
      } catch (_) {}
    }

    if (loginAfterRegister) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyRole, role.name);
    }
  }

  /// Cierra la sesión activa
  static Future<void> logout() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      AuditService().logAuthEvent(userId: userId, action: 'LOGOUT').catchError((_) {});
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserId);
  }

  /// Obtiene el correo del usuario actualmente autenticado
  static Future<String?> getCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Obtiene el ID único del usuario autenticado
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Alias para obtener el ID del psicólogo activo
  static Future<String?> getCurrentPsychologistId() async {
    return getCurrentUserId();
  }

  /// Indica si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyEmail);
  }

  /// Obtiene el rol del usuario actual
  static Future<UserRole> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_keyRole);
    if (roleName == UserRole.admin.name) {
      return UserRole.admin;
    }
    return UserRole.psychologist;
  }

  /// Verifica si el usuario debe cambiar su contraseña
  static Future<bool> mustChangePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('must_change_password') ?? false;
  }

  /// Actualiza nombre, cédula y especialidad del psicólogo
  static Future<void> updatePsychologistProfile({
    required String psychologistId,
    required String fullName,
    required String licenseNumber,
    required String specialty,
  }) async {
    final existing = await _localDb.getPsychologist(psychologistId);
    if (existing == null) {
      throw const AuthException('No se encontró el perfil del psicólogo');
    }
    final updated = Psychologist(
      id: existing.id,
      fullName: fullName.trim(),
      email: existing.email,
      licenseNumber: licenseNumber.trim(),
      specialty: specialty.trim(),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      active: existing.active,
    );
    await _localDb.updatePsychologist(updated);
    _remoteDb.updatePsychologistProfile(
      psychologistId,
      fullName.trim(),
      licenseNumber.trim(),
      specialty.trim(),
      email: existing.email,
    ).catchError((_) {});
  }

  /// Cambia la contraseña de un usuario
  static Future<void> changePassword({
    required String userId,
    required String userEmail,
    required String newPassword,
    String cedulaConfirmation = '',
    bool isAdmin = false,
  }) async {
    if (newPassword.length < 6) {
      throw const AuthException('La contraseña debe tener al menos 6 caracteres');
    }

    // Validar cédula si es psicólogo
    if (!isAdmin) {
      final psycho = await _localDb.getPsychologist(userId);
      if (psycho == null) {
        throw const AuthException('No se encontró el perfil del psicólogo');
      }
      if (psycho.licenseNumber.trim().isEmpty) {
        throw const AuthException(
            'No tienes cédula registrada. Regístrala en la pestaña "Perfil" primero.');
      }
      if (cedulaConfirmation.trim().toLowerCase() != psycho.licenseNumber.trim().toLowerCase()) {
        throw const AuthException('La cédula profesional no coincide. Verifica e intenta de nuevo.');
      }
    }

    final newHash = hashPassword(newPassword);
    await _localDb.updateUserPasswordHash(userId, userEmail, newHash);
    _remoteDb.updateUserPassword(userEmail, newHash).catchError((_) {});

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('must_change_password');

    AuditService().logAuthEvent(userId: userId, action: 'PASSWORD_CHANGE').catchError((_) {});
  }

  /// Descarga datos remotos si hay conexión configurada
  static Future<void> syncOnLogin() async {
    try {
      final uri = await MongoDBService.getConfiguredUri();
      if (uri.isNotEmpty) {
        await SyncService().syncNow();
      }
    } catch (_) {}
  }
}
