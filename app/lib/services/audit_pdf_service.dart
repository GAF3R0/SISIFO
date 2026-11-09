import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/evaluation.dart';
import '../models/psychologist.dart';

class AuditPdfService {
  static Future<String> generateAndShareAuditReport({
    required List<Evaluation> evaluations,
    required List<Psychologist> psychologists,
    required String adminEmail,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Estadísticas
    final totalEvals = evaluations.length;
    final totalPsychos = psychologists.length;
    final highRiskCount = evaluations.where((e) =>
        e.riskLevel == 'moderately_severe' || e.riskLevel == 'severe').length;
    final moderateRiskCount = evaluations.where((e) => e.riskLevel == 'moderate').length;
    final lowRiskCount = evaluations.where((e) => e.riskLevel == 'none' || e.riskLevel == 'mild').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabecera
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SISIFO - REPORTE DE AUDITORÍA CLÍNICA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Generado por: $adminEmail', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Fecha: ${dateFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text('ROL: ADMIN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Resumen de Métricas
            pw.Text('Resumen Global del Sistema', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildStatBox('Evaluaciones', '$totalEvals', PdfColors.blue800),
                pw.SizedBox(width: 8),
                _buildStatBox('Psicólogos', '$totalPsychos', PdfColors.teal800),
                pw.SizedBox(width: 8),
                _buildStatBox('Riesgo Alto/Severo', '$highRiskCount', PdfColors.red800),
                pw.SizedBox(width: 8),
                _buildStatBox('Riesgo Moderado', '$moderateRiskCount', PdfColors.amber800),
                pw.SizedBox(width: 8),
                _buildStatBox('Riesgo Bajo/Nulo', '$lowRiskCount', PdfColors.green800),
              ],
            ),
            pw.SizedBox(height: 20),

            // Sección Psicólogos Registrados
            pw.Text('Psicólogos Registrados en la Plataforma', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (psychologists.isEmpty)
              pw.Text('No hay psicólogos registrados en la base de datos.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Nombre Completo', 'Correo', 'Cédula', 'Especialidad'],
                data: psychologists.map((p) => [
                  p.fullName,
                  p.email,
                  p.licenseNumber.isEmpty ? 'N/A' : p.licenseNumber,
                  p.specialty,
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
            pw.SizedBox(height: 20),

            // Sección Evaluaciones Realizadas
            pw.Text('Auditoría de Evaluaciones Realizadas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (evaluations.isEmpty)
              pw.Text('No hay evaluaciones registradas en el sistema.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Severidad PHQ-9', 'Riesgo IA', 'Score IA', 'Estado Sinc.'],
                data: evaluations.map((e) => [
                  dateFormat.format(e.timestamp),
                  e.phq9Severity,
                  e.riskLevel.toUpperCase(),
                  '${(e.riskScore * 100).toStringAsFixed(0)}%',
                  e.syncStatus.name.toUpperCase(),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
          ];
        },
      ),
    );

    // Guardar directamente en el almacenamiento de descargas del dispositivo
    final bytes = await pdf.save();
    final fileName = 'Auditoria_Sisifo_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Intentar guardar en Downloads (/sdcard/Download) si está disponible
    Directory? saveDir;
    try {
      final dlDir = Directory('/storage/emulated/0/Download');
      if (await dlDir.exists()) {
        saveDir = dlDir;
      }
    } catch (_) {}

    // Si no hay acceso a Downloads, usar el directorio de documentos de la app
    saveDir ??= await getApplicationDocumentsDirectory();

    final filePath = '${saveDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('PDF guardado en: $filePath');
    return filePath;
  }

  static pw.Widget _buildStatBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(title, style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );
  }
}
