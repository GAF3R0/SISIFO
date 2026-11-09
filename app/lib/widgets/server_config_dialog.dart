import 'package:flutter/material.dart';
import '../services/mongodb_service.dart';

/// Diálogo para configurar la URI de MongoDB Atlas de forma segura.
/// Solo el administrador debe acceder a esta pantalla.
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _uriController = TextEditingController();
  bool _isLoading = false;
  bool _isTesting = false;
  String? _statusMessage;
  bool _statusOk = false;
  bool _obscureUri = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUri();
  }

  Future<void> _loadCurrentUri() async {
    final uri = await MongoDBService.getConfiguredUri();
    if (mounted && uri.isNotEmpty) {
      setState(() => _uriController.text = uri);
    }
  }

  Future<void> _testConnection() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) {
      setState(() {
        _statusMessage = 'Ingrese una URI de conexión.';
        _statusOk = false;
      });
      return;
    }
    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });
    try {
      await MongoDBService.setUri(uri);
      final ok = await MongoDBService().testConnection();
      setState(() {
        _statusMessage = ok
            ? '✅ Conexión exitosa con MongoDB Atlas.'
            : '❌ No se pudo conectar. Verifique la URI y el acceso de red.';
        _statusOk = ok;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _statusOk = false;
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await MongoDBService.setUri(uri);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearConfig() async {
    await MongoDBService.clearUri();
    if (mounted) {
      setState(() {
        _uriController.clear();
        _statusMessage = 'Configuración eliminada.';
        _statusOk = false;
      });
    }
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_outlined, color: Color(0xFF2E86AB)),
          SizedBox(width: 8),
          Text('Configuración del Servidor', style: TextStyle(fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                '⚠️ Medida de seguridad (LFPDPPP Art. 19):\n'
                'La URI de base de datos se almacena localmente de forma protegida en el dispositivo y no está fijada en el código fuente.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _uriController,
              obscureText: _obscureUri,
              decoration: InputDecoration(
                labelText: 'URI de MongoDB Atlas',
                hintText: 'mongodb+srv://usuario:contraseña@cluster...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.storage_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureUri ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureUri = !_obscureUri),
                ),
              ),
              maxLines: 1,
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusOk ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusOk ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _clearConfig,
          child: const Text('Limpiar', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _isTesting ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Probar conexión'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E86AB), foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
