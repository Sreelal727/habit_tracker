class MilestoneDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int color;
  final String category; // proof_count, streak, group_completion
  final int targetValue;
  final int coinReward;
  final int sortOrder;

  const MilestoneDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.targetValue,
    required this.coinReward,
    required this.sortOrder,
  });

  factory MilestoneDefinition.fromJson(Map<String, dynamic> json) {
    return MilestoneDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFD700,
      category: json['category'] as String? ?? 'proof_count',
      targetValue: json['target_value'] as int? ?? 1,
      coinReward: json['coin_reward'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class UserMilestone {
  final String id;
  final String userId;
  final String milestoneId;
  final int currentValue;
  final bool completed;
  final DateTime? completedAt;
  final bool coinsClaimed;
  final MilestoneDefinition? definition;

  const UserMilestone({
    required this.id,
    required this.userId,
    required this.milestoneId,
    required this.currentValue,
    required this.completed,
    this.completedAt,
    required this.coinsClaimed,
    this.definition,
  });

  factory UserMilestone.fromJson(Map<String, dynamic> json) {
    final def = json['milestone_definitions'] as Map<String, dynamic>?;
    return UserMilestone(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      milestoneId: json['milestone_id'] as String,
      currentValue: json['current_value'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      coinsClaimed: json['coins_claimed'] as bool? ?? false,
      definition: def != null ? MilestoneDefinition.fromJson(def) : null,
    );
  }

  double get progressPercent {
    if (definition == null) return 0.0;
    if (definition!.targetValue <= 0) return 1.0;
    return (currentValue / definition!.targetValue).clamp(0.0, 1.0);
  }
}
