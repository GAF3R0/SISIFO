import 'package:flutter/material.dart';
import '../models/psychologist.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Diálogo para editar nombre/cédula/especialidad y cambiar contraseña.
/// [psychologist] es el perfil a editar (puede ser el propio o uno externo si es admin).
/// [currentUserId] es quien está haciendo la edición (para verificar si es admin).
class EditProfileDialog extends StatefulWidget {
  final Psychologist psychologist;
  final UserRole editorRole; // rol del usuario que edita
  final VoidCallback onSaved;

  const EditProfileDialog({
    super.key,
    required this.psychologist,
    required this.editorRole,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Psychologist psychologist,
    required UserRole editorRole,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditProfileDialog(
        psychologist: psychologist,
        editorRole: editorRole,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Perfil
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _specialtyCtrl;
  bool _isSavingProfile = false;

  // Contraseña
  final _pwFormKey = GlobalKey<FormState>();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController(); // para confirmar si es psicólogo
  bool _isSavingPw = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameCtrl = TextEditingController(text: widget.psychologist.fullName);
    _licenseCtrl = TextEditingController(text: widget.psychologist.licenseNumber);
    _specialtyCtrl = TextEditingController(text: widget.psychologist.specialty);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _specialtyCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await AuthService.updatePsychologistProfile(
        psychologistId: widget.psychologist.id,
        fullName: _nameCtrl.text,
        licenseNumber: _licenseCtrl.text,
        specialty: _specialtyCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF2E86AB),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_pwFormKey.currentState!.validate()) return;
    setState(() => _isSavingPw = true);
    try {
      await AuthService.changePassword(
        userId: widget.psychologist.id,
        userEmail: widget.psychologist.email,
        newPassword: _newPwCtrl.text,
        cedulaConfirmation: _cedulaCtrl.text,
        isAdmin: widget.editorRole == UserRole.admin,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: Color(0xFF2E86AB),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.editorRole == UserRole.admin;

    final mediaQuery = MediaQuery.of(context);
    final dialogContentHeight = (mediaQuery.size.height * 0.52).clamp(320.0, 420.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2E86AB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar: ${widget.psychologist.fullName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E86AB),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E86AB),
              tabs: const [
                Tab(icon: Icon(Icons.person, size: 18), text: 'Perfil'),
                Tab(icon: Icon(Icons.lock_reset, size: 18), text: 'Contraseña'),
              ],
            ),

            // Contenido
            SizedBox(
              height: dialogContentHeight,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── TAB 1: PERFIL ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo *',
                              prefixIcon: Icon(Icons.badge),
                              isDense: true,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _licenseCtrl,
                            enabled: isAdmin,
                            decoration: InputDecoration(
                              labelText: 'Cédula profesional',
                              prefixIcon: const Icon(Icons.credit_card),
                              isDense: true,
                              helperText: isAdmin ? null : 'Solo el administrador puede modificar la cédula',
                              helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _specialtyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Especialidad',
                              prefixIcon: Icon(Icons.school),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSavingProfile ? null : _saveProfile,
                              icon: _isSavingProfile
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save),
                              label: const Text('Guardar cambios'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E86AB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── TAB 2: CONTRASEÑA ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _pwFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Si es psicólogo editando su propia cuenta, pide cédula como confirmación
                          if (!isAdmin) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Confirma tu identidad con tu cédula profesional',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _cedulaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cédula profesional *',
                                prefixIcon: Icon(Icons.credit_card),
                                isDense: true,
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Requerido para confirmar identidad' : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _newPwCtrl,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña *',
                              prefixIcon: const Icon(Icons.lock_outline),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPwCtrl,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña *',
                              prefixIcon: const Icon(Icons.lock),
                              isDense: true,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) =>
                                v != _newPwCtrl.text ? 'Las contraseñas no coinciden' : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSavingPw ? null : _savePassword,
                              icon: _isSavingPw
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.lock_reset),
                              label: const Text('Cambiar contraseña'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
