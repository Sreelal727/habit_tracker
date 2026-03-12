import 'package:drift/drift.dart';

class PremiumUnlocks extends Table {
  TextColumn get id => text()();
  TextColumn get featureKey => text()(); // 'theme_ocean', 'advanced_graphs', etc.
  IntColumn get coinCost => integer()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
