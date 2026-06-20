import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> ensureSqliteFfiBindings() async {
  /// Android / iOS / macOS: default sqflite platform implementation.
  if (!Platform.isWindows && !Platform.isLinux) return;

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
