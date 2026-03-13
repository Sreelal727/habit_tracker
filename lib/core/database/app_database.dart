import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/habits.dart';
import 'tables/habit_entries.dart';
import 'tables/goals.dart';
import 'tables/goal_entries.dart';
import 'tables/rewards.dart';
import 'tables/user_settings.dart';
import 'tables/coin_transactions.dart';
import 'tables/premium_unlocks.dart';
import 'daos/habit_dao.dart';
import 'daos/habit_entry_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/goal_entry_dao.dart';
import 'daos/user_settings_dao.dart';
import 'daos/coin_dao.dart';
import 'daos/premium_unlock_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Habits,
    HabitEntries,
    Goals,
    GoalEntries,
    Rewards,
    UserSettings,
    CoinTransactions,
    PremiumUnlocks,
  ],
  daos: [
    HabitDao,
    HabitEntryDao,
    GoalDao,
    GoalEntryDao,
    UserSettingsDao,
    CoinDao,
    PremiumUnlockDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  factory AppDatabase() {
    return _instance ??= AppDatabase._();
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(coinTransactions);
            await migrator.createTable(premiumUnlocks);
          }
          if (from < 3) {
            await customStatement(
              "ALTER TABLE habits ADD COLUMN customization TEXT NOT NULL DEFAULT '{}'",
            );
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE habit_entries ADD COLUMN completion_percent INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE goal_entries ADD COLUMN completion_percent INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'UPDATE habit_entries SET completion_percent = 100 WHERE completed = 1',
            );
            await customStatement(
              'UPDATE goal_entries SET completion_percent = 100 WHERE completed = 1',
            );
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'habit_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
