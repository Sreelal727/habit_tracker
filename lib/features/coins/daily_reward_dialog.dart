import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../config/theme/app_colors.dart';
import 'coins_notifier.dart';

class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _claimed = false;
  int _earnedCoins = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinsState = ref.watch(coinsProvider);
    final streak = coinsState.dailyStreak;
    final streakBonus = ((streak + 1) * CoinRewards.streakBonusPerDay)
        .clamp(0, CoinRewards.maxStreakBonus);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated coin icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: RotationTransition(
                    turns: _rotateAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _claimed ? Icons.check_circle : Icons.monetization_on,
                        size: 48,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _claimed ? 'Reward Claimed!' : 'Daily Reward',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (!_claimed) ...[
              Text(
                'Open the app daily to earn coins!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              // Reward breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _RewardRow(
                      label: 'Daily bonus',
                      coins: CoinRewards.dailyBase,
                    ),
                    if (streakBonus > 0) ...[
                      const Divider(height: 16),
                      _RewardRow(
                        label: 'Streak bonus (${streak + 1} days)',
                        coins: streakBonus,
                        isBonus: true,
                      ),
                    ],
                    const Divider(height: 16),
                    _RewardRow(
                      label: 'Total',
                      coins: CoinRewards.dailyBase + streakBonus,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Streak display
              if (streak > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$streak day streak!',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _claimReward,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Claim Reward',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '+$_earnedCoins coins',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Balance: ${coinsState.coinBalance} coins',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _claimReward() async {
    final earned =
        await ref.read(coinsProvider.notifier).claimDailyReward();
    if (mounted) {
      _controller.reset();
      _controller.forward();
      setState(() {
        _claimed = true;
        _earnedCoins = earned;
      });
    }
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final int coins;
  final bool isBonus;
  final bool isBold;

  const _RewardRow({
    required this.label,
    required this.coins,
    this.isBonus = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBonus ? Colors.orange : null,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.monetization_on,
              size: 16,
              color: isBonus ? Colors.orange : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              '+$coins',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBonus ? Colors.orange : AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
