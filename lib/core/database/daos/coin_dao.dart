import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/coin_transactions.dart';

part 'coin_dao.g.dart';

@DriftAccessor(tables: [CoinTransactions])
class CoinDao extends DatabaseAccessor<AppDatabase> with _$CoinDaoMixin {
  CoinDao(super.db);

  Future<void> insertTransaction(CoinTransactionsCompanion transaction) {
    return into(coinTransactions).insert(transaction);
  }

  Future<List<CoinTransaction>> getTransactionHistory() {
    return (select(coinTransactions)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<CoinTransaction>> getTransactionsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(coinTransactions)
          ..where(
              (t) => t.createdAt.isBiggerOrEqualValue(start) & t.createdAt.isSmallerThanValue(end)))
        .get();
  }
}
