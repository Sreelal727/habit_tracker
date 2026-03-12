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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(coinTransactions);
            await migrator.createTable(premiumUnlocks);
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
