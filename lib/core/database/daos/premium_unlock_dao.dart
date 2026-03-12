import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/premium_unlocks.dart';

part 'premium_unlock_dao.g.dart';

@DriftAccessor(tables: [PremiumUnlocks])
class PremiumUnlockDao extends DatabaseAccessor<AppDatabase>
    with _$PremiumUnlockDaoMixin {
  PremiumUnlockDao(super.db);

  Future<void> insertUnlock(PremiumUnlocksCompanion unlock) {
    return into(premiumUnlocks).insert(unlock);
  }

  Future<List<PremiumUnlock>> getUnlockedFeatures() {
    return select(premiumUnlocks).get();
  }

  Future<bool> isFeatureUnlocked(String featureKey) async {
    final result = await (select(premiumUnlocks)
          ..where((u) => u.featureKey.equals(featureKey)))
        .get();
    return result.isNotEmpty;
  }
}
