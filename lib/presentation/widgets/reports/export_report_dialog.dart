import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/services/report_export_service.dart';
import '../../providers/repository_providers.dart';

Future<void> showReportExportDialog(
  BuildContext context,
  WidgetRef ref, {
  ExportPeriodType? initialPeriodType,
  DateTime? initialReferenceDate,
}) async {
  ExportDataScope scope = ExportDataScope.all;
  ExportPeriodType periodType = initialPeriodType ?? ExportPeriodType.month;
  DateTime referenceDate = initialReferenceDate ?? DateTime.now();
  ExportFileFormat format = ExportFileFormat.pdf;
  ExportPreview? preview;
  bool loadingPreview = false;
  bool exporting = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final service = ref.read(reportExportServiceProvider);
          final request = ExportRequest(
            scope: scope,
            periodType: periodType,
            referenceDate: referenceDate,
            format: format,
          );
          final fileName = service.buildFileName(request);

          Future<void> loadPreview() async {
            setState(() => loadingPreview = true);
            try {
              final data = await service.preview(request);
              if (!ctx.mounted) return;
              setState(() => preview = data);
            } catch (_) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر جلب معاينة التقرير')),
              );
            } finally {
              if (ctx.mounted) setState(() => loadingPreview = false);
            }
          }

          Future<void> exportNow() async {
            setState(() => exporting = true);
            try {
              final result = await service.export(request);
              if (result.preview.rowsCount == 0) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لا توجد بيانات للفترة المختارة'),
                  ),
                );
                return;
              }
              await Share.shareXFiles([XFile(result.file.path)]);
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تصدير ${result.fileName}')),
              );
              Navigator.of(ctx).pop();
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
            } finally {
              if (ctx.mounted) setState(() => exporting = false);
            }
          }

          return AlertDialog(
            title: const Text('تصدير التقارير'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<ExportDataScope>(
                      value: scope,
                      decoration: const InputDecoration(
                        labelText: 'نوع البيانات',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ExportDataScope.expenses,
                          child: Text('المصاريف فقط'),
                        ),
                        DropdownMenuItem(
                          value: ExportDataScope.incomes,
                          child: Text('الدخل فقط'),
                        ),
                        DropdownMenuItem(
                          value: ExportDataScope.all,
                          child: Text('الكل'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          scope = v;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExportPeriodType>(
                      value: periodType,
                      decoration: const InputDecoration(labelText: 'الفترة'),
                      items: const [
                        DropdownMenuItem(
                          value: ExportPeriodType.day,
                          child: Text('يوم'),
                        ),
                        DropdownMenuItem(
                          value: ExportPeriodType.month,
                          child: Text('شهر'),
                        ),
                        DropdownMenuItem(
                          value: ExportPeriodType.year,
                          child: Text('سنة'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          periodType = v;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _referenceDateText(periodType, referenceDate),
                      ),
                      subtitle: const Text('التاريخ المرجعي'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final selected = await _pickReferenceDate(
                          context: ctx,
                          periodType: periodType,
                          current: referenceDate,
                        );
                        if (selected == null) return;
                        setState(() {
                          referenceDate = selected;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ExportFileFormat>(
                      value: format,
                      decoration: const InputDecoration(
                        labelText: 'صيغة الملف',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ExportFileFormat.pdf,
                          child: Text('PDF'),
                        ),
                        DropdownMenuItem(
                          value: ExportFileFormat.excel,
                          child: Text('Excel'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          format = v;
                          preview = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('اسم الملف المتوقع: $fileName'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: loadingPreview ? null : loadPreview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(
                        loadingPreview ? 'جاري الفحص...' : 'فحص البيانات',
                      ),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 8),
                      Text('عدد السجلات: ${preview!.rowsCount}'),
                      Text(
                        'إجمالي الدخل: ${(preview!.totalIncomeMinor / 100).toStringAsFixed(2)}',
                      ),
                      Text(
                        'إجمالي المصاريف: ${(preview!.totalExpensesMinor / 100).toStringAsFixed(2)}',
                      ),
                      Text(
                        'الصافي: ${((preview!.totalIncomeMinor - preview!.totalExpensesMinor) / 100).toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: exporting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton.icon(
                onPressed: exporting ? null : exportNow,
                icon: const Icon(Icons.ios_share_outlined),
                label: Text(exporting ? 'جاري التصدير...' : 'تصدير'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<DateTime?> _pickReferenceDate({
  required BuildContext context,
  required ExportPeriodType periodType,
  required DateTime current,
}) async {
  switch (periodType) {
    case ExportPeriodType.day:
      return showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
    case ExportPeriodType.month:
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
      );
      if (picked == null) return null;
      return DateTime(picked.year, picked.month, 1);
    case ExportPeriodType.year:
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
      );
      if (picked == null) return null;
      return DateTime(picked.year, 1, 1);
  }
}

String _referenceDateText(ExportPeriodType periodType, DateTime date) {
  switch (periodType) {
    case ExportPeriodType.day:
      return DateFormat('yyyy-MM-dd').format(date);
    case ExportPeriodType.month:
      return DateFormat('yyyy-MM').format(date);
    case ExportPeriodType.year:
      return DateFormat('yyyy').format(date);
  }
}
