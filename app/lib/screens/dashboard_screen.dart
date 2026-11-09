import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/assessment_provider.dart';
import '../models/evaluation.dart';
import '../models/psychologist.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/database_helper.dart';
import '../services/audit_pdf_service.dart';
import '../widgets/risk_badge.dart';
import '../widgets/add_psychologist_dialog.dart';
import '../widgets/evaluation_detail_modal.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/server_config_dialog.dart';

/// Dashboard adaptativo según el rol:
/// - ADMIN: Auditoría del sistema, generación de PDF, registro y visualización de psicólogos. (NO ve ni agrega pacientes/evaluaciones).
/// - PSICÓLOGO: Evaluaciones clínicas, registro de pacientes, consulta de resultados detallados y sincronización.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userEmail = '';
  String _userName = '';
  UserRole _userRole = UserRole.psychologist;
  String _currentUserId = '';
  bool _isSyncing = false;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  List<Evaluation> _evaluations = [];
  List<Psychologist> _psychologists = [];

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadData();
    _syncOnStart();
  }

  Future<void> _syncOnStart() async {
    try {
      final res = await SyncService().syncNow();
      if (mounted && (res.downloadedCount > 0 || res.syncedCount > 0)) {
        await _loadData();
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos al volver de otras pantallas (ej: resultado de evaluación)
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final email = await AuthService.getCurrentEmail();
    final role = await AuthService.getCurrentRole();
    final userId = await AuthService.getCurrentUserId();

    List<Evaluation> evals = [];
    List<Psychologist> psychos = [];
    String displayName = email ?? '';

    if (role == UserRole.admin) {
      psychos = await _dbHelper.getAllPsychologists();
      evals = await _dbHelper.getAllEvaluations();
      // Para admin: asegurar registro y obtener nombre
      if (userId != null) {
        var adminPsy = await _dbHelper.getPsychologist(userId);
        if (adminPsy == null) {
          adminPsy = Psychologist(
            id: userId,
            fullName: 'Administrador',
            email: email ?? 'admin@gmail.com',
            licenseNumber: 'ADMIN',
            specialty: 'Administración del Sistema',
          );
          await _dbHelper.insertPsychologist(adminPsy);
        }
        displayName = adminPsy.fullName;
      }
      // Filtrar el perfil propio del admin de la lista de psicólogos que administra
      psychos = psychos.where((p) => p.id != userId && p.email != 'admin@gmail.com').toList();
    } else {
      // Filtrar estrictamente solo las consultas de pacientes pertenecientes a este psicólogo
      if (userId != null && userId.isNotEmpty) {
        evals = await _dbHelper.getEvaluationsByPsychologist(userId, email: email);
      } else {
        evals = [];
      }
      // Para psicólogo: obtener nombre del perfil
      if (userId != null) {
        var psy = await _dbHelper.getPsychologist(userId);
        if (psy == null && email != null) {
          psy = Psychologist(
            id: userId,
            fullName: email.split('@').first,
            email: email,
            licenseNumber: '',
            specialty: 'Psicología Clínica',
          );
          await _dbHelper.insertPsychologist(psy);
        }
        if (psy != null && psy.fullName.isNotEmpty) {
          displayName = psy.fullName;
        }
      }
    }

    if (mounted) {
      setState(() {
        _userEmail = email ?? '';
        _userName = displayName;
        _userRole = role;
        _currentUserId = userId ?? '';
        _evaluations = evals;
        _psychologists = psychos;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEditOwnProfile() async {
    final userId = _currentUserId;
    if (userId.isEmpty) return;

    var psycho = await _dbHelper.getPsychologist(userId);
    if (psycho == null) {
      psycho = Psychologist(
        id: userId,
        fullName: _userName.isNotEmpty
            ? _userName
            : (_userRole == UserRole.admin ? 'Administrador' : _userEmail.split('@').first),
        email: _userEmail,
        licenseNumber: _userRole == UserRole.admin ? 'ADMIN' : '',
        specialty: _userRole == UserRole.admin ? 'Administración' : 'Psicología Clínica',
      );
      await _dbHelper.insertPsychologist(psycho);
    }

    if (mounted) {
      EditProfileDialog.show(
        context,
        psychologist: psycho,
        editorRole: _userRole,
        onSaved: _loadData,
      );
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    final result = await SyncService().syncNow();
    await _loadData();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? const Color(0xFF2E86AB) : Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) context.go('/login');
  }

  Future<void> _handleGenerateAuditPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final path = await AuditPdfService.generateAndShareAuditReport(
        evaluations: _evaluations,
        psychologists: _psychologists,
        adminEmail: _userEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en:\n$path'),
            backgroundColor: Colors.teal.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _userRole == UserRole.admin ? 'Sisifo - Administración' : 'Sisifo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Mi Perfil / Contraseña',
            onPressed: _handleEditOwnProfile,
          ),
          if (_userRole == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configuración de Conexión',
              onPressed: () => ServerConfigDialog.show(context),
            ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.cloud_sync),
            tooltip: 'Sincronizar con MongoDB Atlas',
            onPressed: _isSyncing ? null : _handleSync,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await SyncService().syncNow();
          await _loadData();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userRole == UserRole.admin
                ? _buildAdminView(theme)
                : _buildPsychologistView(theme),
      ),
      floatingActionButton: _userRole == UserRole.admin
          ? FloatingActionButton.extended(
              onPressed: () => AddPsychologistDialog.show(context, _loadData),
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar Psicólogo'),
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // ==========================================
  // VISTA PARA ROL ADMINISTRADOR
  // ==========================================
  Widget _buildAdminView(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Saludo y Perfil Admin
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2E86AB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Panel de Control',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ADMINISTRADOR',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _userName.isNotEmpty ? _userName : _userEmail,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: _handleEditOwnProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Editar mi perfil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Botón Generar Reporte de Auditoría PDF
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingPdf ? null : _handleGenerateAuditPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            label: const Text(
              'Generar Auditoría del Sistema (PDF)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Resumen Métricas
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('Psicólogos', '${_psychologists.length}', Icons.groups, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard('Evaluaciones Totales', '${_evaluations.length}', Icons.analytics, Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Lista de Psicólogos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Psicólogos Registrados (${_psychologists.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadData,
              tooltip: 'Recargar',
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_psychologists.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No hay psicólogos registrados aún.', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  const Text('Usa el botón inferior para dar de alta al primer psicólogo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ..._psychologists.map((psy) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                  child: const Icon(Icons.psychology, color: Color(0xFF2E86AB)),
                ),
                title: Text(psy.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${psy.email}\nCédula: ${psy.licenseNumber.isEmpty ? "N/A" : psy.licenseNumber} • ${psy.specialty}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF2E86AB)),
                  tooltip: 'Editar psicólogo y contraseña',
                  onPressed: () {
                    EditProfileDialog.show(
                      context,
                      psychologist: psy,
                      editorRole: UserRole.admin,
                      onSaved: _loadData,
                    );
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 70), // Espacio para FAB
      ],
    );
  }

  // ==========================================
  // VISTA PARA ROL PSICÓLOGO
  // ==========================================
  Widget _buildPsychologistView(ThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saludo y Perfil Psicólogo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF2E86AB),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bienvenido/a',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PSICÓLOGO',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _userName.isNotEmpty ? _userName : _userEmail,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: _handleEditOwnProfile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Editar perfil', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Botón Nueva Evaluación
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<AssessmentProvider>().reset();
                context.push('/consent');
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Nueva evaluación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E86AB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Encabezado de evaluaciones registradas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consultas de Pacientes (${_evaluations.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadData,
                tooltip: 'Recargar',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Lista de evaluaciones reales con botón de consulta
        Expanded(
          child: _evaluations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('No hay evaluaciones registradas aún.', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Presiona "Nueva evaluación" para comenzar.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _evaluations.length,
                  itemBuilder: (context, i) {
                    final eval = _evaluations[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => EvaluationDetailModal.show(context, eval),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF2E86AB).withValues(alpha: 0.1),
                                child: const Icon(Icons.person_outline, color: Color(0xFF2E86AB)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      eval.patientName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(eval.timestamp),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      'Severidad: ${eval.phq9Severity}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  RiskBadge(riskLevel: eval.riskLevel, fontSize: 11),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ver detalle',
                                        style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                      Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, MaterialColor color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade700, size: 24),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
