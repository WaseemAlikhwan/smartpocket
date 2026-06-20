import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/notification_service.dart';
import '../../core/services/debt_reminder_service.dart';
import '../../core/services/recurring_engine_service.dart';

/// Bottom navigation wrapping [StatefulNavigationShell].
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  bool _startedEngine = false;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'الرئيسية',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      label: 'الأقسام',
    ),
    NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'التقارير'),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'الإعدادات',
    ),
  ];

  void _openAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('إضافة مصروف'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/expense/add');
                },
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('إضافة دخل'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/income/add');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedEngine) return;
    _startedEngine = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      if (!mounted) return;
      final engine = RecurringEngineService(ref);
      await engine.processDue(context);
      if (!mounted) return;
      final reminders = DebtReminderService(ref);
      await reminders.processDueReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.navigationShell.currentIndex;

    return Scaffold(
      body: SafeArea(child: widget.navigationShell),
      floatingActionButton:
          idx == 0
              ? FloatingActionButton(
                tooltip: 'إضافة',
                onPressed: () => _openAddMenu(context),
                child: const Icon(Icons.add),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: widget.navigationShell.goBranch,
      ),
    );
  }
}
