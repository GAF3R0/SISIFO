import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AddPsychologistDialog extends StatefulWidget {
  final VoidCallback onPsychologistAdded;

  const AddPsychologistDialog({super.key, required this.onPsychologistAdded});

  static Future<void> show(BuildContext context, VoidCallback onAdded) {
    return showDialog(
      context: context,
      builder: (_) => AddPsychologistDialog(onPsychologistAdded: onAdded),
    );
  }

  @override
  State<AddPsychologistDialog> createState() => _AddPsychologistDialogState();
}

class _AddPsychologistDialogState extends State<AddPsychologistDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController(text: 'Psicología Clínica');
  final _passwordController = TextEditingController(text: '123456');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        rawEmail: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        licenseNumber: _licenseController.text.trim(),
        specialty: _specialtyController.text.trim(),
        role: UserRole.psychologist,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPsychologistAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Psicólogo registrado exitosamente'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Color(0xFF2E86AB)),
          SizedBox(width: 8),
          Text('Registrar Psicólogo', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.badge),
                  isDense: true,
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico *',
                  prefixIcon: Icon(Icons.email),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || !val.contains('@')) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña de acceso *',
                  prefixIcon: Icon(Icons.lock),
                  isDense: true,
                ),
                validator: (val) => (val == null || val.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'Cédula profesional',
                  prefixIcon: Icon(Icons.credit_card),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Especialidad',
                  prefixIcon: Icon(Icons.school),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E86AB),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Registrar'),
        ),
      ],
    );
  }
}
