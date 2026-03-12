// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_unlock_dao.dart';

// ignore_for_file: type=lint
mixin _$PremiumUnlockDaoMixin on DatabaseAccessor<AppDatabase> {
  $PremiumUnlocksTable get premiumUnlocks => attachedDatabase.premiumUnlocks;
  PremiumUnlockDaoManager get managers => PremiumUnlockDaoManager(this);
}

class PremiumUnlockDaoManager {
  final _$PremiumUnlockDaoMixin _db;
  PremiumUnlockDaoManager(this._db);
  $$PremiumUnlocksTableTableManager get premiumUnlocks =>
      $$PremiumUnlocksTableTableManager(
        _db.attachedDatabase,
        _db.premiumUnlocks,
      );
}
