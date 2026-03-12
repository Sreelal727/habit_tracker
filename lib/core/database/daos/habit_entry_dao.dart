import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habit_entries.dart';
import '../tables/habits.dart';

part 'habit_entry_dao.g.dart';

@DriftAccessor(tables: [HabitEntries, Habits])
class HabitEntryDao extends DatabaseAccessor<AppDatabase>
    with _$HabitEntryDaoMixin {
  HabitEntryDao(super.db);

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Stream<List<HabitEntry>> watchEntriesForDate(DateTime date) {
    final d = _dateOnly(date);
    return (select(habitEntries)..where((e) => e.date.equals(d))).watch();
  }

  Future<List<HabitEntry>> getEntriesForDate(DateTime date) {
    final d = _dateOnly(date);
    return (select(habitEntries)..where((e) => e.date.equals(d))).get();
  }

  Future<List<HabitEntry>> getEntriesForRange(
      DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    return (select(habitEntries)
          ..where(
              (entry) => entry.date.isBiggerOrEqualValue(s) & entry.date.isSmallerOrEqualValue(e)))
        .get();
  }

  Future<void> toggleEntry(String id, String habitId, DateTime date) async {
    final d = _dateOnly(date);
    final existing = await (select(habitEntries)
          ..where((e) => e.habitId.equals(habitId) & e.date.equals(d)))
        .getSingleOrNull();

    if (existing != null) {
      if (existing.completed) {
        await (update(habitEntries)
              ..where((e) => e.id.equals(existing.id)))
            .write(const HabitEntriesCompanion(
          completed: Value(false),
          completedAt: Value(null),
        ));
      } else {
        await (update(habitEntries)
              ..where((e) => e.id.equals(existing.id)))
            .write(HabitEntriesCompanion(
          completed: const Value(true),
          completedAt: Value(DateTime.now()),
        ));
      }
    } else {
      await into(habitEntries).insert(HabitEntriesCompanion.insert(
        id: id,
        habitId: habitId,
        date: d,
        completed: const Value(true),
        completedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<int> getConsecutiveDays(String habitId) async {
    final now = _dateOnly(DateTime.now());
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final entry = await (select(habitEntries)
            ..where((e) =>
                e.habitId.equals(habitId) &
                e.date.equals(date) &
                e.completed.equals(true)))
          .getSingleOrNull();

      if (entry != null) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<double> getCompletionRate(
      String habitId, DateTime start, DateTime end) async {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final totalDays = e.difference(s).inDays + 1;
    if (totalDays <= 0) return 0;

    final completed = await (select(habitEntries)
          ..where((entry) =>
              entry.habitId.equals(habitId) &
              entry.date.isBiggerOrEqualValue(s) &
              entry.date.isSmallerOrEqualValue(e) &
              entry.completed.equals(true)))
        .get();

    return completed.length / totalDays;
  }

  Future<Map<DateTime, int>> getDailyCompletionCounts(
      DateTime start, DateTime end) async {
    final entries = await getEntriesForRange(start, end);
    final Map<DateTime, int> counts = {};
    for (final entry in entries) {
      if (entry.completed) {
        final d = _dateOnly(entry.date);
        counts[d] = (counts[d] ?? 0) + 1;
      }
    }
    return counts;
  }
}
