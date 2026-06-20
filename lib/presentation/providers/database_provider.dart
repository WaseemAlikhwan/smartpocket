import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Overridden in [main] once the SQLite database is opened.
final databaseProvider = Provider<Database>(
  (_) => throw UnimplementedError('databaseProvider must be overridden'),
);
