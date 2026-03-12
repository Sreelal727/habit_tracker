// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coin_dao.dart';

// ignore_for_file: type=lint
mixin _$CoinDaoMixin on DatabaseAccessor<AppDatabase> {
  $CoinTransactionsTable get coinTransactions =>
      attachedDatabase.coinTransactions;
  CoinDaoManager get managers => CoinDaoManager(this);
}

class CoinDaoManager {
  final _$CoinDaoMixin _db;
  CoinDaoManager(this._db);
  $$CoinTransactionsTableTableManager get coinTransactions =>
      $$CoinTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.coinTransactions,
      );
}
