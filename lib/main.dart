import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/database/database_helper.dart';
import 'core/database/sqlite_ffi_gate.dart';
import 'presentation/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ensureSqliteFfiBindings();

  final db = await DatabaseHelper().database;

  final router = createAppRouter();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: SmartPocketApp(router: router),
    ),
  );
}
