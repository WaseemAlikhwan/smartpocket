import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/expense_local_datasource.dart';
import '../datasources/local/income_local_datasource.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';

enum ExportDataScope { expenses, incomes, all }

enum ExportPeriodType { day, month, year }

enum ExportFileFormat { pdf, excel }

class ExportRequest {
  const ExportRequest({
    required this.scope,
    required this.periodType,
    required this.referenceDate,
    required this.format,
  });

  final ExportDataScope scope;
  final ExportPeriodType periodType;
  final DateTime referenceDate;
  final ExportFileFormat format;
}

class ExportPreview {
  const ExportPreview({
    required this.rowsCount,
    required this.totalIncomeMinor,
    required this.totalExpensesMinor,
  });

  final int rowsCount;
  final int totalIncomeMinor;
  final int totalExpensesMinor;
}

class ReportExportResult {
  const ReportExportResult({
    required this.file,
    required this.preview,
    required this.fileName,
  });

  final File file;
  final ExportPreview preview;
  final String fileName;
}

class ReportExportService {
  ReportExportService(this._expenses, this._incomes, this._categories);

  final ExpenseLocalDataSource _expenses;
  final IncomeLocalDataSource _incomes;
  final CategoryLocalDataSource _categories;

  Future<ExportPreview> preview(ExportRequest request) async {
    final data = await _collect(request);
    return ExportPreview(
      rowsCount: data.rows.length,
      totalIncomeMinor: data.totalIncomeMinor,
      totalExpensesMinor: data.totalExpensesMinor,
    );
  }

  String buildFileName(ExportRequest request) {
    final scope = switch (request.scope) {
      ExportDataScope.expenses => 'expenses',
      ExportDataScope.incomes => 'incomes',
      ExportDataScope.all => 'all',
    };
    final period = switch (request.periodType) {
      ExportPeriodType.day => DateFormat(
        'yyyy-MM-dd',
      ).format(request.referenceDate),
      ExportPeriodType.month => DateFormat(
        'yyyy-MM',
      ).format(request.referenceDate),
      ExportPeriodType.year => DateFormat('yyyy').format(request.referenceDate),
    };
    final ext = request.format == ExportFileFormat.pdf ? 'pdf' : 'xlsx';
    return 'report_${scope}_$period.$ext';
  }

  Future<ReportExportResult> export(ExportRequest request) async {
    final data = await _collect(request);
    final fileName = buildFileName(request);
    final bytes =
        request.format == ExportFileFormat.pdf
            ? await _buildPdfBytes(request, data)
            : _buildExcelBytes(request, data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return ReportExportResult(
      file: file,
      preview: ExportPreview(
        rowsCount: data.rows.length,
        totalIncomeMinor: data.totalIncomeMinor,
        totalExpensesMinor: data.totalExpensesMinor,
      ),
      fileName: fileName,
    );
  }

  (_DateRange, String) _resolveRangeAndLabel(ExportRequest request) {
    final local = request.referenceDate;
    switch (request.periodType) {
      case ExportPeriodType.day:
        final start = DateTime(local.year, local.month, local.day);
        final end = start.add(const Duration(days: 1));
        return (
          _DateRange(start.toUtc(), end.toUtc()),
          DateFormat('yyyy-MM-dd').format(local),
        );
      case ExportPeriodType.month:
        final start = DateTime(local.year, local.month, 1);
        final end =
            local.month == 12
                ? DateTime(local.year + 1, 1, 1)
                : DateTime(local.year, local.month + 1, 1);
        return (
          _DateRange(start.toUtc(), end.toUtc()),
          DateFormat('yyyy-MM').format(local),
        );
      case ExportPeriodType.year:
        final start = DateTime(local.year, 1, 1);
        final end = DateTime(local.year + 1, 1, 1);
        return (
          _DateRange(start.toUtc(), end.toUtc()),
          DateFormat('yyyy').format(local),
        );
    }
  }

  Future<_CollectedData> _collect(ExportRequest request) async {
    final (range, label) = _resolveRangeAndLabel(request);
    final categories = await _categories.getAll();
    final categoryNameById = {for (final c in categories) c.id: c.name};

    final expenses =
        request.scope == ExportDataScope.incomes
            ? const <ExpenseModel>[]
            : await _expenses.getBetween(
              startInclusive: range.startInclusive,
              endExclusive: range.endExclusive,
            );
    final incomes =
        request.scope == ExportDataScope.expenses
            ? const <IncomeModel>[]
            : await _incomes.getBetween(
              startInclusive: range.startInclusive,
              endExclusive: range.endExclusive,
            );

    final rows = <_ExportRow>[
      ...expenses.map(
        (e) => _ExportRow(
          date: e.date.toLocal(),
          typeLabel: 'مصروف',
          title: categoryNameById[e.categoryId] ?? e.categoryId,
          note: e.note,
          amountMinor: -e.amountMinor,
          currencyCode: e.currencyCode,
        ),
      ),
      ...incomes.map(
        (i) => _ExportRow(
          date: i.date.toLocal(),
          typeLabel: 'دخل',
          title: i.source.isEmpty ? 'غير محدد' : i.source,
          note: '',
          amountMinor: i.amountMinor,
          currencyCode: i.currencyCode,
        ),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final totalIncomeMinor = incomes.fold<int>(
      0,
      (sum, i) => sum + i.amountMinor,
    );
    final totalExpensesMinor = expenses.fold<int>(
      0,
      (sum, e) => sum + e.amountMinor,
    );

    return _CollectedData(
      periodLabel: label,
      rows: rows,
      totalIncomeMinor: totalIncomeMinor,
      totalExpensesMinor: totalExpensesMinor,
    );
  }

  Future<Uint8List> _buildPdfBytes(
    ExportRequest request,
    _CollectedData data,
  ) async {
    final doc = pw.Document();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final currency = NumberFormat('#,##0.00');
    final net = data.totalIncomeMinor - data.totalExpensesMinor;
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (_) => [
              pw.Text(
                'SmartPocket Export',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Type: ${_scopeLabel(request.scope)}'),
              pw.Text(
                'Period: ${_periodLabel(request.periodType)} ${data.periodLabel}',
              ),
              pw.Text('Rows: ${data.rows.length}'),
              pw.Text(
                'Income: ${currency.format(data.totalIncomeMinor / 100)}',
              ),
              pw.Text(
                'Expenses: ${currency.format(data.totalExpensesMinor / 100)}',
              ),
              pw.Text('Net: ${currency.format(net / 100)}'),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Type', 'Title', 'Note', 'Amount'],
                data:
                    data.rows
                        .map(
                          (r) => [
                            formatter.format(r.date),
                            r.typeLabel,
                            r.title,
                            r.note,
                            '${r.amountMinor < 0 ? '-' : '+'}${currency.format(r.amountMinor.abs() / 100)}',
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  Uint8List _buildExcelBytes(ExportRequest request, _CollectedData data) {
    final excel = Excel.createExcel();
    final summarySheet = excel['Summary'];
    final detailsSheet = excel['Details'];
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    summarySheet.appendRow([
      TextCellValue('Scope'),
      TextCellValue(_scopeLabel(request.scope)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Period'),
      TextCellValue('${_periodLabel(request.periodType)} ${data.periodLabel}'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Rows'),
      IntCellValue(data.rows.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Income Minor'),
      IntCellValue(data.totalIncomeMinor),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Expenses Minor'),
      IntCellValue(data.totalExpensesMinor),
    ]);
    summarySheet.appendRow([
      TextCellValue('Net Minor'),
      IntCellValue(data.totalIncomeMinor - data.totalExpensesMinor),
    ]);

    detailsSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Title'),
      TextCellValue('Note'),
      TextCellValue('Amount Minor'),
      TextCellValue('Currency'),
    ]);
    for (final row in data.rows) {
      detailsSheet.appendRow([
        TextCellValue(formatter.format(row.date)),
        TextCellValue(row.typeLabel),
        TextCellValue(row.title),
        TextCellValue(row.note),
        IntCellValue(row.amountMinor),
        TextCellValue(row.currencyCode),
      ]);
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? <int>[]);
  }

  String _scopeLabel(ExportDataScope scope) {
    switch (scope) {
      case ExportDataScope.expenses:
        return 'المصاريف';
      case ExportDataScope.incomes:
        return 'الدخل';
      case ExportDataScope.all:
        return 'الكل';
    }
  }

  String _periodLabel(ExportPeriodType periodType) {
    switch (periodType) {
      case ExportPeriodType.day:
        return 'يوم';
      case ExportPeriodType.month:
        return 'شهر';
      case ExportPeriodType.year:
        return 'سنة';
    }
  }
}

class _DateRange {
  const _DateRange(this.startInclusive, this.endExclusive);
  final DateTime startInclusive;
  final DateTime endExclusive;
}

class _ExportRow {
  const _ExportRow({
    required this.date,
    required this.typeLabel,
    required this.title,
    required this.note,
    required this.amountMinor,
    required this.currencyCode,
  });

  final DateTime date;
  final String typeLabel;
  final String title;
  final String note;
  final int amountMinor;
  final String currencyCode;
}

class _CollectedData {
  const _CollectedData({
    required this.periodLabel,
    required this.rows,
    required this.totalIncomeMinor,
    required this.totalExpensesMinor,
  });

  final String periodLabel;
  final List<_ExportRow> rows;
  final int totalIncomeMinor;
  final int totalExpensesMinor;
}
