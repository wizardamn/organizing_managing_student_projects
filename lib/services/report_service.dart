import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';

class ReportService {
  Future<void> generateAndPrint(List<Project> list) async {
    if (list.isEmpty) return;

    final doc = pw.Document();

    // Основной стиль
    final titleStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );

    final cellStyle = pw.TextStyle(fontSize: 11);

    // Создание страницы с таблицей
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(child: pw.Text('Отчёт по проектам', style: titleStyle)),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['Название', 'Срок', 'Статус', 'Оценка'],
            headerStyle: headerStyle,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: cellStyle,
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
            data: list.map((p) {
              return [
                p.title,
                DateFormat('dd.MM.yyyy').format(p.deadline),
                _statusRu(p.status),
                p.grade?.toString() ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    // Печать
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  String _statusRu(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planned:
        return 'Запланирован';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.completed:
        return 'Завершён';
    }
  }
}
