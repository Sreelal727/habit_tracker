import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'milestone_model.dart';
import 'milestone_notifier.dart';
import 'milestone_celebration_dialog.dart';
import '../../config/theme/app_colors.dart';

class MilestonesScreen extends ConsumerStatefulWidget {
  const MilestonesScreen({super.key});

  @override
  ConsumerState<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends ConsumerState<MilestonesScreen> {
  @override
  void initState() {
    super.initState();
    // Check for celebrations after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCelebrations();
    });
  }

  void _checkCelebrations() {
    final milestoneState = ref.read(milestoneProvider);
    if (milestoneState.recentlyCompleted.isNotEmpty) {
      final milestoneId = milestoneState.recentlyCompleted.first;
      final def = milestoneState.definitions.firstWhere(
        (d) => d.id == milestoneId,
      );
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MilestoneCelebrationDialog(
          milestone: def,
          onClaim: () async {
            await ref.read(milestoneProvider.notifier).claimReward(milestoneId);
            ref.read(milestoneProvider.notifier).clearRecentlyCompleted();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestoneState = ref.watch(milestoneProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Milestones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(milestoneProvider.notifier).refresh(),
          ),
        ],
      ),
      body: milestoneState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : milestoneState.definitions.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(milestoneProvider.notifier).refresh();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // In Progress section
                      if (milestoneState.inProgress.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'In Progress',
                          icon: Icons.trending_up,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        ...milestoneState.inProgress.map(
                          (d) => _MilestoneCard(
                            definition: d,
                            userMilestone: milestoneState.progress[d.id],
                            onClaim: () => _claimReward(d.id),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Completed section
                      if (milestoneState.completed.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Completed',
                          icon: Icons.emoji_events,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        ...milestoneState.completed.map(
                          (d) => _MilestoneCard(
                            definition: d,
                            userMilestone: milestoneState.progress[d.id],
                            onClaim: () => _claimReward(d.id),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Not Started section
                      if (milestoneState.notStarted.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Not Started',
                          icon: Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        ...milestoneState.notStarted.map(
                          (d) => _MilestoneCard(
                            definition: d,
                            userMilestone: milestoneState.progress[d.id],
                            onClaim: null,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No milestones yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Milestones will appear as you\ncomplete habits and earn proofs.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimReward(String milestoneId) async {
    final success =
        await ref.read(milestoneProvider.notifier).claimReward(milestoneId);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coins claimed!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final MilestoneDefinition definition;
  final UserMilestone? userMilestone;
  final VoidCallback? onClaim;

  const _MilestoneCard({
    required this.definition,
    this.userMilestone,
    this.onClaim,
  });

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'fire':
        return Icons.local_fire_department;
      case 'trophy':
        return Icons.emoji_events;
      case 'medal':
        return Icons.military_tech;
      case 'target':
        return Icons.gps_fixed;
      case 'rocket':
        return Icons.rocket_launch;
      case 'lightning':
        return Icons.bolt;
      case 'heart':
        return Icons.favorite;
      case 'group':
        return Icons.group;
      case 'camera':
        return Icons.camera_alt;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(definition.color);
    final currentValue = userMilestone?.currentValue ?? 0;
    final isCompleted = userMilestone?.completed ?? false;
    final isClaimed = userMilestone?.coinsClaimed ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(definition.icon),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        definition.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        definition.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Coin reward badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${definition.coinReward}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: userMilestone?.progressPercent ?? 0.0,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentValue / ${definition.targetValue}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Completed state
            if (isCompleted) ...[
              const SizedBox(height: 12),
              if (!isClaimed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.redeem, size: 18),
                    label: Text('Claim ${definition.coinReward} Coins'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'Completed${userMilestone?.completedAt != null ? ' on ${DateFormat('MMM d, y').format(userMilestone!.completedAt!)}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
