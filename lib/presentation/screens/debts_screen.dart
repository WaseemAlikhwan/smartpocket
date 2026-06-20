import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/finance_top_tabs.dart';
import '../utils/amount_parser.dart';
import '../utils/invalidate_finance.dart';
import '../utils/money_format.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

enum _DebtStatusFilter { all, pending, paid }

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  _DebtStatusFilter _statusFilter = _DebtStatusFilter.all;
  DateTime? _dateFilter;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(
      () => _dateFilter = DateTime(picked.year, picked.month, picked.day),
    );
  }

  List<DebtEntity> _applyFilters(List<DebtEntity> list) {
    return list.where((e) {
      final statusOk = switch (_statusFilter) {
        _DebtStatusFilter.all => true,
        _DebtStatusFilter.pending => e.status == DebtStatus.pending,
        _DebtStatusFilter.paid => e.status == DebtStatus.paid,
      };
      final dateOk =
          _dateFilter == null
              ? true
              : (e.dueDate.year == _dateFilter!.year &&
                  e.dueDate.month == _dateFilter!.month &&
                  e.dueDate.day == _dateFilter!.day);
      return statusOk && dateOk;
    }).toList();
  }

  Future<void> _markFullPaid(DebtEntity debt) async {
    await ref.read(debtRepositoryProvider).markPaid(debt.id);
    invalidateFinanceCaches(ref);
  }

  Future<void> _openPartialPaymentDialog(DebtEntity debt) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('دفعة جزئية'),
            content: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع',
                helperText:
                    'المتبقي: ${(debt.remainingAmountMinor / 100).toStringAsFixed(2)}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    final parsed = parseUserAmount(ctrl.text);
    if (parsed == null || parsed <= 0) return;
    await ref
        .read(debtRepositoryProvider)
        .markPayment(id: debt.id, paidAmountMinor: minorFromMajor(parsed));
    invalidateFinanceCaches(ref);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final debts = ref.watch(allDebtsProvider);
    final baseCurrencyCode = ref.watch(appSettingsProvider).valueOrNull?.baseCurrencyCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الديون'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          const FinanceTopTabs(activeTab: FinanceTopTab.debts),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: debts.when(
              data: (list) {
                final oweTotal = list
                    .where((e) => e.type == DebtType.owedByMe)
                    .fold<int>(0, (s, e) => s + e.remainingAmountMinor);
                final owedTotal = list
                    .where((e) => e.type == DebtType.owedToMe)
                    .fold<int>(0, (s, e) => s + e.remainingAmountMinor);
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'ديون عليك',
                        value: formatMinorUnits(
                          oweTotal,
                          locale,
                          currencyCode: baseCurrencyCode,
                        ),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        title: 'ديون لك',
                        value: formatMinorUnits(
                          owedTotal,
                          locale,
                          currencyCode: baseCurrencyCode,
                        ),
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<_DebtStatusFilter>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: _DebtStatusFilter.all,
                              child: Text('الكل'),
                            ),
                            DropdownMenuItem(
                              value: _DebtStatusFilter.pending,
                              child: Text('غير مدفوع'),
                            ),
                            DropdownMenuItem(
                              value: _DebtStatusFilter.paid,
                              child: Text('مدفوع'),
                            ),
                          ],
                          onChanged:
                              (v) => setState(
                                () =>
                                    _statusFilter = v ?? _DebtStatusFilter.all,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _dateFilter == null
                              ? 'تاريخ'
                              : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_dateFilter!),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            () => setState(() {
                              _dateFilter = null;
                              _statusFilter = _DebtStatusFilter.all;
                            }),
                        child: const Text('مسح'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          debts.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد ديون حالياً')),
                );
              }
              final owe = _applyFilters(
                list.where((e) => e.type == DebtType.owedByMe).toList(),
              );
              final owed = _applyFilters(
                list.where((e) => e.type == DebtType.owedToMe).toList(),
              );
              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [Tab(text: 'ديون عليك'), Tab(text: 'ديون لك')],
                    ),
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        children: [
                          _DebtList(
                            list: owe,
                            locale: locale,
                            onMarkPaid: _markFullPaid,
                            onPartialPay: _openPartialPaymentDialog,
                            onOpen: (id) => context.push('/debt/$id'),
                          ),
                          _DebtList(
                            list: owed,
                            locale: locale,
                            onMarkPaid: _markFullPaid,
                            onPartialPay: _openPartialPaymentDialog,
                            onOpen: (id) => context.push('/debt/$id'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text('$e')),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/debt/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  const _DebtList({
    required this.list,
    required this.locale,
    required this.onMarkPaid,
    required this.onPartialPay,
    required this.onOpen,
  });

  final List<DebtEntity> list;
  final String locale;
  final Future<void> Function(DebtEntity debt) onMarkPaid;
  final Future<void> Function(DebtEntity debt) onPartialPay;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const Center(child: Text('لا توجد عناصر مطابقة.'));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final e = list[i];
        final isPaid = e.status == DebtStatus.paid;
        final color = e.type == DebtType.owedByMe ? Colors.red : Colors.green;
        return ListTile(
          leading: Icon(
            e.type == DebtType.owedByMe ? Icons.call_made : Icons.call_received,
            color: color,
          ),
          title: Text(e.personName),
          subtitle: Text(
            'الإجمالي ${formatMinorUnits(e.amountMinor, locale, currencyCode: e.currencyCode)}'
            ' · المدفوع ${formatMinorUnits(e.paidAmountMinor, locale, currencyCode: e.currencyCode)}'
            ' · المتبقي ${formatMinorUnits(e.remainingAmountMinor, locale, currencyCode: e.currencyCode)}'
            '\nالاستحقاق ${MaterialLocalizations.of(context).formatMediumDate(e.dueDate)}'
            '${isPaid ? ' · مدفوع' : ' · غير مدفوع'}',
          ),
          isThreeLine: true,
          trailing:
              isPaid
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'partial') await onPartialPay(e);
                      if (v == 'paid') await onMarkPaid(e);
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'partial',
                            child: Text('دفعة جزئية'),
                          ),
                          PopupMenuItem(
                            value: 'paid',
                            child: Text('تم الدفع بالكامل'),
                          ),
                        ],
                  ),
          onTap: () => onOpen(e.id),
        );
      },
    );
  }
}
