import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/goals.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  Stream<List<Goal>> watchGoalsByType(String type) {
    return (select(goals)
          ..where((g) => g.type.equals(type) & g.isArchived.equals(false))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .watch();
  }

  Future<List<Goal>> getGoalsByType(String type) {
    return (select(goals)
          ..where((g) => g.type.equals(type) & g.isArchived.equals(false))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  Future<void> insertGoal(GoalsCompanion goal) {
    return into(goals).insert(goal);
  }

  Future<void> updateGoal(GoalsCompanion goal) {
    return (update(goals)..where((g) => g.id.equals(goal.id.value)))
        .write(goal);
  }

  Future<void> deleteGoal(String id) {
    return (delete(goals)..where((g) => g.id.equals(id))).go();
  }

  Future<void> archiveGoal(String id) {
    return (update(goals)..where((g) => g.id.equals(id)))
        .write(const GoalsCompanion(isArchived: Value(true)));
  }
}
