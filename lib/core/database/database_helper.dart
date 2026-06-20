import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/db_constants.dart';
import '../constants/default_categories.dart';

class DatabaseHelper {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, DbConstants.dbName);
    return openDatabase(
      path,
      version: DbConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await _seedDefaults(db);
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateV2ToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateV3ToV4(db);
        }
        if (oldVersion < 5) {
          await _migrateV4ToV5(db);
        }
        if (oldVersion < 6) {
          await _migrateV5ToV6(db);
        }
        if (oldVersion < 7) {
          await _migrateV6ToV7(db);
        }
        if (oldVersion < 8) {
          await _migrateV7ToV8(db);
        }
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableExpenses} (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES ${DbConstants.tableCategories} (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_expenses_date ON ${DbConstants.tableExpenses} (date)
    ''');
    await db.execute('''
      CREATE INDEX idx_expenses_category ON ${DbConstants.tableExpenses} (category_id)
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableBudgets} (
        id TEXT PRIMARY KEY NOT NULL,
        category_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        limit_amount_minor INTEGER NOT NULL,
        alert_period TEXT NOT NULL DEFAULT 'month',
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES ${DbConstants.tableCategories} (id) ON DELETE CASCADE,
        UNIQUE (category_id, year, month)
      )
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSettings} (
        id TEXT PRIMARY KEY NOT NULL,
        opening_balance_minor INTEGER NOT NULL DEFAULT 0,
        default_monthly_income_minor INTEGER NOT NULL DEFAULT 0,
        base_currency_code TEXT NOT NULL DEFAULT 'SYP',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        budget_alert_period TEXT NOT NULL DEFAULT 'month',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableIncomes} (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor INTEGER NOT NULL,
        date TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT '',
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_incomes_date ON ${DbConstants.tableIncomes} (date)
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableDebts} (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor INTEGER NOT NULL,
        paid_amount_minor INTEGER NOT NULL DEFAULT 0,
        remaining_amount_minor INTEGER NOT NULL DEFAULT 0,
        person_name TEXT NOT NULL,
        contact_id TEXT,
        due_date TEXT NOT NULL,
        debt_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        last_payment_at TEXT,
        reminder_last_sent_at TEXT,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_debts_due ON ${DbConstants.tableDebts} (due_date)
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableDebtPayments} (
        id TEXT PRIMARY KEY NOT NULL,
        debt_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        paid_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (debt_id) REFERENCES ${DbConstants.tableDebts}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_debt_payments_debt ON ${DbConstants.tableDebtPayments} (debt_id, paid_at DESC)
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableRecurringEntries} (
        id TEXT PRIMARY KEY NOT NULL,
        entry_kind TEXT NOT NULL,
        title TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        day_of_month INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        payload_json TEXT NOT NULL DEFAULT '{}',
        last_confirmed_ym TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_recurring_active_day ON ${DbConstants.tableRecurringEntries} (is_active, day_of_month)
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSavingsGoals} (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        target_amount_minor INTEGER NOT NULL,
        saved_amount_minor INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        target_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSavingsGoalContributions} (
        id TEXT PRIMARY KEY NOT NULL,
        goal_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        source TEXT NOT NULL,
        linked_expense_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES ${DbConstants.tableSavingsGoals}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_saving_contrib_goal_created ON ${DbConstants.tableSavingsGoalContributions}(goal_id, created_at DESC)
    ''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.execute(
      "ALTER TABLE ${DbConstants.tableExpenses} ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'SYP'",
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSettings} (
        id TEXT PRIMARY KEY NOT NULL,
        opening_balance_minor INTEGER NOT NULL DEFAULT 0,
        default_monthly_income_minor INTEGER NOT NULL DEFAULT 0,
        base_currency_code TEXT NOT NULL DEFAULT 'SYP',
        onboarding_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableIncomes} (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor INTEGER NOT NULL,
        date TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT '',
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_incomes_date ON ${DbConstants.tableIncomes} (date)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableDebts} (
        id TEXT PRIMARY KEY NOT NULL,
        amount_minor INTEGER NOT NULL,
        paid_amount_minor INTEGER NOT NULL DEFAULT 0,
        remaining_amount_minor INTEGER NOT NULL DEFAULT 0,
        person_name TEXT NOT NULL,
        contact_id TEXT,
        due_date TEXT NOT NULL,
        debt_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        last_payment_at TEXT,
        reminder_last_sent_at TEXT,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debts_due ON ${DbConstants.tableDebts} (due_date)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableRecurringEntries} (
        id TEXT PRIMARY KEY NOT NULL,
        entry_kind TEXT NOT NULL,
        title TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        day_of_month INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        payload_json TEXT NOT NULL DEFAULT '{}',
        last_confirmed_ym TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recurring_active_day ON ${DbConstants.tableRecurringEntries} (is_active, day_of_month)',
    );
  }

  Future<void> _migrateV2ToV3(Database db) async {
    await db.execute(
      "ALTER TABLE ${DbConstants.tableDebts} ADD COLUMN paid_amount_minor INTEGER NOT NULL DEFAULT 0",
    );
    await db.execute(
      "ALTER TABLE ${DbConstants.tableDebts} ADD COLUMN remaining_amount_minor INTEGER NOT NULL DEFAULT 0",
    );
    await db.execute(
      "ALTER TABLE ${DbConstants.tableDebts} ADD COLUMN contact_id TEXT",
    );
    await db.execute(
      "ALTER TABLE ${DbConstants.tableDebts} ADD COLUMN last_payment_at TEXT",
    );
    await db.execute(
      "ALTER TABLE ${DbConstants.tableDebts} ADD COLUMN reminder_last_sent_at TEXT",
    );
    await db.execute(
      "UPDATE ${DbConstants.tableDebts} SET remaining_amount_minor = amount_minor WHERE remaining_amount_minor = 0",
    );
    await db.execute(
      "UPDATE ${DbConstants.tableDebts} SET status = CASE WHEN status IN ('settled','paid') THEN 'paid' ELSE 'pending' END",
    );
    await db.execute(
      "UPDATE ${DbConstants.tableDebts} SET paid_amount_minor = CASE WHEN status = 'paid' THEN amount_minor ELSE paid_amount_minor END",
    );
  }

  Future<void> _migrateV4ToV5(Database db) async {
    await db.execute(
      "ALTER TABLE ${DbConstants.tableSettings} ADD COLUMN budget_alert_period TEXT NOT NULL DEFAULT 'month'",
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSavingsGoals} (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        target_amount_minor INTEGER NOT NULL,
        saved_amount_minor INTEGER NOT NULL DEFAULT 0,
        target_date TEXT NOT NULL,
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateV5ToV6(Database db) async {
    await db.execute(
      "ALTER TABLE ${DbConstants.tableBudgets} ADD COLUMN alert_period TEXT NOT NULL DEFAULT 'month'",
    );
  }

  /// Rebuild savings goals table from scratch (drop old rows by product decision).
  Future<void> _migrateV6ToV7(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ${DbConstants.tableSavingsGoals}');
    await db.execute('''
      CREATE TABLE ${DbConstants.tableSavingsGoals} (
        id TEXT PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        target_amount_minor INTEGER NOT NULL,
        saved_amount_minor INTEGER NOT NULL DEFAULT 0,
        start_date TEXT NOT NULL,
        target_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        currency_code TEXT NOT NULL DEFAULT 'SYP',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateV7ToV8(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableSavingsGoalContributions} (
        id TEXT PRIMARY KEY NOT NULL,
        goal_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        source TEXT NOT NULL,
        linked_expense_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES ${DbConstants.tableSavingsGoals}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_saving_contrib_goal_created ON ${DbConstants.tableSavingsGoalContributions}(goal_id, created_at DESC)
    ''');
  }

  Future<void> _migrateV3ToV4(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableDebtPayments} (
        id TEXT PRIMARY KEY NOT NULL,
        debt_id TEXT NOT NULL,
        amount_minor INTEGER NOT NULL,
        paid_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (debt_id) REFERENCES ${DbConstants.tableDebts}(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON ${DbConstants.tableDebtPayments} (debt_id, paid_at DESC)',
    );
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final seed in defaultCategories) {
      await db.insert(DbConstants.tableCategories, {
        'id': seed.id,
        'name': seed.name,
        'icon_key': seed.iconKey,
        'color_value': seed.colorValue,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
