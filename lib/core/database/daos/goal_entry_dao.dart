import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/goal_entries.dart';
import '../tables/goals.dart';

part 'goal_entry_dao.g.dart';

@DriftAccessor(tables: [GoalEntries, Goals])
class GoalEntryDao extends DatabaseAccessor<AppDatabase>
    with _$GoalEntryDaoMixin {
  GoalEntryDao(super.db);

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Stream<List<GoalEntry>> watchEntriesForDate(DateTime date) {
    final d = _dateOnly(date);
    return (select(goalEntries)..where((e) => e.date.equals(d))).watch();
  }

  Future<List<GoalEntry>> getEntriesForDate(DateTime date) {
    final d = _dateOnly(date);
    return (select(goalEntries)..where((e) => e.date.equals(d))).get();
  }

  Future<void> toggleEntry(String id, String goalId, DateTime date) async {
    final d = _dateOnly(date);
    final existing = await (select(goalEntries)
          ..where((e) => e.goalId.equals(goalId) & e.date.equals(d)))
        .getSingleOrNull();

    if (existing != null) {
      if (existing.completed) {
        await (update(goalEntries)
              ..where((e) => e.id.equals(existing.id)))
            .write(const GoalEntriesCompanion(
          completed: Value(false),
          completionPercent: Value(0),
          completedAt: Value(null),
        ));
      } else {
        await (update(goalEntries)
              ..where((e) => e.id.equals(existing.id)))
            .write(GoalEntriesCompanion(
          completed: const Value(true),
          completionPercent: const Value(100),
          completedAt: Value(DateTime.now()),
        ));
      }
    } else {
      await into(goalEntries).insert(GoalEntriesCompanion.insert(
        id: id,
        goalId: goalId,
        date: d,
        completed: const Value(true),
        completionPercent: const Value(100),
        completedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> updateCompletionPercent(
      String id, String goalId, DateTime date, int percent) async {
    final d = _dateOnly(date);
    final clamped = percent.clamp(0, 100);
    final isCompleted = clamped >= 100;
    final existing = await (select(goalEntries)
          ..where((e) => e.goalId.equals(goalId) & e.date.equals(d)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(goalEntries)
            ..where((e) => e.id.equals(existing.id)))
          .write(GoalEntriesCompanion(
        completed: Value(isCompleted),
        completionPercent: Value(clamped),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ));
    } else {
      await into(goalEntries).insert(GoalEntriesCompanion.insert(
        id: id,
        goalId: goalId,
        date: d,
        completed: Value(isCompleted),
        completionPercent: Value(clamped),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ));
    }
  }

  Future<Map<DateTime, int>> getDailyGoalCompletionCounts(
      DateTime start, DateTime end) async {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final entries = await (select(goalEntries)
          ..where((entry) =>
              entry.date.isBiggerOrEqualValue(s) &
              entry.date.isSmallerOrEqualValue(e) &
              entry.completed.equals(true)))
        .get();
    final Map<DateTime, int> counts = {};
    for (final entry in entries) {
      final d = _dateOnly(entry.date);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return counts;
  }
}
