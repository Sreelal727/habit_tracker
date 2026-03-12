import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/constants.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/coin_dao.dart';
import '../../core/database/daos/premium_unlock_dao.dart';
import '../../core/database/daos/user_settings_dao.dart';
import '../../providers/app_providers.dart';

class CoinsState {
  final int coinBalance;
  final int dailyStreak;
  final String lastClaimDate;
  final bool canClaimToday;
  final Set<String> unlockedFeatures;
  final bool isLoading;

  const CoinsState({
    this.coinBalance = 0,
    this.dailyStreak = 0,
    this.lastClaimDate = '',
    this.canClaimToday = true,
    this.unlockedFeatures = const {},
    this.isLoading = true,
  });

  CoinsState copyWith({
    int? coinBalance,
    int? dailyStreak,
    String? lastClaimDate,
    bool? canClaimToday,
    Set<String>? unlockedFeatures,
    bool? isLoading,
  }) {
    return CoinsState(
      coinBalance: coinBalance ?? this.coinBalance,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      canClaimToday: canClaimToday ?? this.canClaimToday,
      unlockedFeatures: unlockedFeatures ?? this.unlockedFeatures,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CoinsNotifier extends StateNotifier<CoinsState> {
  final UserSettingsDao _settingsDao;
  final CoinDao _coinDao;
  final PremiumUnlockDao _premiumUnlockDao;
  static const _uuid = Uuid();

  CoinsNotifier(this._settingsDao, this._coinDao, this._premiumUnlockDao)
      : super(const CoinsState()) {
    loadState();
  }

  Future<void> loadState() async {
    final balance =
        int.tryParse(await _settingsDao.getValue('coin_balance') ?? '0') ?? 0;
    final streak = int.tryParse(
            await _settingsDao.getValue('daily_open_streak') ?? '0') ??
        0;
    final lastClaim =
        await _settingsDao.getValue('last_reward_claim_date') ?? '';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final canClaim = lastClaim != today;

    final unlocks = await _premiumUnlockDao.getUnlockedFeatures();
    final unlockedKeys = unlocks.map((u) => u.featureKey).toSet();

    state = CoinsState(
      coinBalance: balance,
      dailyStreak: streak,
      lastClaimDate: lastClaim,
      canClaimToday: canClaim,
      unlockedFeatures: unlockedKeys,
      isLoading: false,
    );
  }

  /// Claims daily reward. Returns the amount earned, or 0 if already claimed.
  Future<int> claimDailyReward() async {
    if (!state.canClaimToday) return 0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    // Calculate streak
    int newStreak;
    if (state.lastClaimDate == yesterday) {
      newStreak = state.dailyStreak + 1;
    } else {
      newStreak = 1;
    }

    // Calculate coins
    final streakBonus = (newStreak * CoinRewards.streakBonusPerDay)
        .clamp(0, CoinRewards.maxStreakBonus);
    final totalEarned = CoinRewards.dailyBase + streakBonus;
    final newBalance = state.coinBalance + totalEarned;

    // Save to database
    await _settingsDao.setValue('coin_balance', newBalance.toString());
    await _settingsDao.setValue('last_reward_claim_date', today);
    await _settingsDao.setValue('daily_open_streak', newStreak.toString());

    // Record transaction
    await _coinDao.insertTransaction(CoinTransactionsCompanion(
      id: Value(_uuid.v4()),
      amount: Value(totalEarned),
      type: const Value('daily_reward'),
      description: Value('Day $newStreak streak bonus'),
      createdAt: Value(DateTime.now()),
    ));

    state = state.copyWith(
      coinBalance: newBalance,
      dailyStreak: newStreak,
      lastClaimDate: today,
      canClaimToday: false,
    );

    return totalEarned;
  }

  /// Spends coins on a premium feature. Returns true if successful.
  Future<bool> purchaseFeature(String featureKey) async {
    final featureInfo = PremiumFeatures.features[featureKey];
    if (featureInfo == null) return false;

    final cost = featureInfo['cost'] as int;
    if (state.coinBalance < cost) return false;
    if (state.unlockedFeatures.contains(featureKey)) return false;

    final newBalance = state.coinBalance - cost;

    // Save to database
    await _settingsDao.setValue('coin_balance', newBalance.toString());

    await _coinDao.insertTransaction(CoinTransactionsCompanion(
      id: Value(_uuid.v4()),
      amount: Value(-cost),
      type: const Value('purchase'),
      description: Value('Purchased ${featureInfo['name']}'),
      createdAt: Value(DateTime.now()),
    ));

    await _premiumUnlockDao.insertUnlock(PremiumUnlocksCompanion(
      id: Value(_uuid.v4()),
      featureKey: Value(featureKey),
      coinCost: Value(cost),
      unlockedAt: Value(DateTime.now()),
    ));

    state = state.copyWith(
      coinBalance: newBalance,
      unlockedFeatures: {...state.unlockedFeatures, featureKey},
    );

    return true;
  }

  bool isFeatureUnlocked(String featureKey) {
    return state.unlockedFeatures.contains(featureKey);
  }
}

final coinsProvider = StateNotifierProvider<CoinsNotifier, CoinsState>((ref) {
  return CoinsNotifier(
    ref.watch(userSettingsDaoProvider),
    ref.watch(coinDaoProvider),
    ref.watch(premiumUnlockDaoProvider),
  );
});
