import 'package:drift/drift.dart';

class CoinTransactions extends Table {
  TextColumn get id => text()();
  IntColumn get amount => integer()(); // positive = earned, negative = spent
  TextColumn get type => text()(); // 'daily_reward', 'streak_bonus', 'purchase'
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
