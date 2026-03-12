import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habits.dart';

part 'habit_dao.g.dart';

@DriftAccessor(tables: [Habits])
class HabitDao extends DatabaseAccessor<AppDatabase> with _$HabitDaoMixin {
  HabitDao(super.db);

  Stream<List<Habit>> watchActiveHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .watch();
  }

  Future<List<Habit>> getActiveHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .get();
  }

  Future<List<Habit>> getAllHabits() {
    return (select(habits)..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .get();
  }

  Future<void> insertHabit(HabitsCompanion habit) {
    return into(habits).insert(habit);
  }

  Future<void> updateHabit(HabitsCompanion habit) {
    return (update(habits)..where((h) => h.id.equals(habit.id.value)))
        .write(habit);
  }

  Future<void> deleteHabit(String id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<void> archiveHabit(String id) {
    return (update(habits)..where((h) => h.id.equals(id)))
        .write(const HabitsCompanion(isArchived: Value(true)));
  }

  Future<void> reorderHabits(List<String> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(habits)..where((h) => h.id.equals(orderedIds[i])))
            .write(HabitsCompanion(sortOrder: Value(i)));
      }
    });
  }
}
