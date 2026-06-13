import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../models/task_model.dart';

class PdfGenerator {
  static String _limitarTexto(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String _getTotalTime(TaskModel task) {
    if (task.reports == null || task.reports!.isEmpty) return '0h 0m';
    double totalHours = task.reports!.fold(
      0.0,
      (sum, r) => sum + (r.hoursWorked ?? 0.0),
    );
    final d = Duration(seconds: (totalHours * 3600).round());
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes.remainder(60)}m';
  }

  static Future<void> generateAndOpenTasksPdf({
    required String title,
    required List<TaskModel> tasks,
  }) async {
    final pdf = pw.Document();

    final pageTheme = pw.PageTheme(
      orientation: pw.PageOrientation.landscape,
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) => [
          _buildHeader(
            fecha: DateTime.now().toString().substring(0, 10),
            text: title,
          ),
          pw.SizedBox(height: 10),
          _tableProducts(tasks),
        ],
        footer: (context) => _buildFooter(),
      ),
    );

    // Guardar el PDF en un archivo temporal
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/reporte_tareas_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // Abrir el archivo generado
    final url = Uri.file(file.path);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (Platform.isWindows) {
        Process.run('explorer', [file.path]);
      } else {
        throw 'No se pudo abrir el archivo PDF en $url';
      }
    }
  }

  static pw.Widget _buildHeader({required String fecha, required String text}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CoopPropera',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Sistema de Gestión de Tareas',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Fecha de Reporte: $fecha',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300, thickness: 1),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _tableProducts(List<TaskModel> listProduct) {
    final headers = [
      'ASIGNADO A',
      'FECHA CREACIÓN',
      'TÍTULO',
      'DESCRIPCIÓN',
      'ESTADO',
      'PRIORIDAD',
      'HORAS TRAB.',
      'CREADO POR',
    ];

    final dataList = listProduct.map((task) {
      return [
        _limitarTexto(task.assignee?.firstName ?? 'Sin Asignar', 15),
        _limitarTexto(task.createdAt.split('T')[0], 10),
        task.title.toUpperCase(),
        _limitarTexto(
          (task.description ?? 'Sin descripción').toUpperCase(),
          40,
        ),
        task.status.toUpperCase(),
        task.priority.toUpperCase(),
        _getTotalTime(task),
        _limitarTexto(task.creator?.firstName ?? 'N/A', 15),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: dataList,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey200),
        verticalInside: pw.BorderSide(color: PdfColors.grey200),
      ),
      tableWidth: pw.TableWidth.max,
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: const pw.TextStyle(fontSize: 8),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.centerLeft, // Asignado
        1: pw.Alignment.center, // Fecha
        2: pw.Alignment.centerLeft, // Titulo
        3: pw.Alignment.centerLeft, // Descripción
        4: pw.Alignment.center, // Estado
        5: pw.Alignment.center, // Prioridad
        6: pw.Alignment.center, // Horas
        7: pw.Alignment.center, // Creado Por
      },
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 8,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.lightBlue900),
      columnWidths: {
        0: const pw.FixedColumnWidth(60), // Asignado
        1: const pw.FixedColumnWidth(55), // Fecha
        2: const pw.FixedColumnWidth(80), // Titulo
        3: const pw.FlexColumnWidth(3), // Descripción (más ancho)
        4: const pw.FixedColumnWidth(50), // Estado
        5: const pw.FixedColumnWidth(50), // Prioridad
        6: const pw.FixedColumnWidth(50), // Horas
        7: const pw.FixedColumnWidth(60), // Creado Por
      },
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: PdfColors.grey300, thickness: 1),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generado automáticamente por CoopPropera',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
