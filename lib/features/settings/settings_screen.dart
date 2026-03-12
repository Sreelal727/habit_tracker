import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme/app_colors.dart';
import '../../features/auth/auth_notifier.dart';
import '../../features/coins/coins_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final coinsState = ref.watch(coinsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          (user?.displayName ?? user?.email ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Coin balance
          ListTile(
            leading: const Icon(Icons.monetization_on,
                color: AppColors.secondary),
            title: const Text('Coin Balance'),
            subtitle: Text('${coinsState.coinBalance} coins'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (coinsState.dailyStreak > 0) ...[
                  const Icon(Icons.local_fire_department,
                      color: Colors.orange, size: 18),
                  Text(' ${coinsState.dailyStreak} day streak',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => context.push('/settings/shop'),
          ),
          const Divider(),
          // Coin Shop
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Coin Shop'),
            subtitle: const Text('Spend coins on themes and features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/shop'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Manage Habits'),
            subtitle: const Text('Reorder, edit, or archive habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/habits'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Habit Tracker v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Habit Tracker',
                applicationVersion: '1.0.0',
                children: [
                  const Text('Track your daily habits and goals.'),
                ],
              );
            },
          ),
          const Divider(),
          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
