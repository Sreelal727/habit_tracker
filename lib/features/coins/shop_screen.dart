import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../config/theme/app_colors.dart';
import 'coins_notifier.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinsState = ref.watch(coinsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.monetization_on,
                  color: AppColors.secondary, size: 18),
              label: Text(
                '${coinsState.coinBalance}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.secondary.withOpacity(0.1),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Balance card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.monetization_on,
                    size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  '${coinsState.coinBalance}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'coins available',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${coinsState.dailyStreak} day streak',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Premium Features',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Spend your coins to unlock features',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          // Feature grid
          ...PremiumFeatures.features.entries.map((entry) {
            final key = entry.key;
            final info = entry.value;
            final isUnlocked = coinsState.unlockedFeatures.contains(key);
            final cost = info['cost'] as int;
            final canAfford = coinsState.coinBalance >= cost;

            return _ShopItem(
              name: info['name'] as String,
              description: info['description'] as String,
              cost: cost,
              iconName: info['icon'] as String,
              isUnlocked: isUnlocked,
              canAfford: canAfford,
              onPurchase: () => _confirmPurchase(context, ref, key, info),
            );
          }),
        ],
      ),
    );
  }

  void _confirmPurchase(BuildContext context, WidgetRef ref, String featureKey,
      Map<String, dynamic> info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unlock ${info['name']}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info['description'] as String),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${info['cost']} coins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(coinsProvider.notifier)
                  .purchaseFeature(featureKey);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '${info['name']} unlocked!'
                        : 'Not enough coins'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final String name;
  final String description;
  final int cost;
  final String iconName;
  final bool isUnlocked;
  final bool canAfford;
  final VoidCallback onPurchase;

  const _ShopItem({
    required this.name,
    required this.description,
    required this.cost,
    required this.iconName,
    required this.isUnlocked,
    required this.canAfford,
    required this.onPurchase,
  });

  IconData _getIcon() {
    switch (iconName) {
      case 'palette':
        return Icons.palette;
      case 'analytics':
        return Icons.analytics;
      case 'calendar_month':
        return Icons.calendar_month;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked
                ? AppColors.success.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUnlocked ? Icons.check_circle : _getIcon(),
            color: isUnlocked ? AppColors.success : AppColors.primary,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: isUnlocked
            ? const Chip(
                label: Text('Owned',
                    style: TextStyle(color: AppColors.success, fontSize: 12)),
                backgroundColor: Color(0x1543A047),
              )
            : FilledButton.icon(
                onPressed: canAfford ? onPurchase : null,
                icon: const Icon(Icons.monetization_on, size: 16),
                label: Text('$cost'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      canAfford ? AppColors.secondary : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
      ),
    );
  }
}
