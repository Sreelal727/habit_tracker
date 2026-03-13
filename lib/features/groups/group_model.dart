class GroupMember {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GroupMember(
      userId: json['user_id'] as String,
      displayName: profile?['display_name'] as String? ?? 'Unknown',
      avatarUrl: profile?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class Group {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final int maxMembers;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMember> members;

  const Group({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.maxMembers,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json,
      {List<GroupMember>? members}) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      maxMembers: json['max_members'] as int? ?? 20,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: members ?? [],
    );
  }
}

class GroupItem {
  final String id;
  final String groupId;
  final String type;
  final String title;
  final String? description;
  final String icon;
  final int color;
  final bool requiresProof;
  final String proofType;
  final String? proofDescription;
  final int sortOrder;
  final String addedBy;
  final DateTime createdAt;

  const GroupItem({
    required this.id,
    required this.groupId,
    required this.type,
    required this.title,
    this.description,
    required this.icon,
    required this.color,
    required this.requiresProof,
    required this.proofType,
    this.proofDescription,
    required this.sortOrder,
    required this.addedBy,
    required this.createdAt,
  });

  factory GroupItem.fromJson(Map<String, dynamic> json) {
    return GroupItem(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      type: json['type'] as String? ?? 'habit',
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'star',
      color: (json['color'] as num?)?.toInt() ?? 0xFF4CAF50,
      requiresProof: json['requires_proof'] as bool? ?? true,
      proofType: json['proof_type'] as String? ?? 'photo',
      proofDescription: json['proof_description'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      addedBy: json['added_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class GroupProgress {
  final String id;
  final String groupId;
  final String itemId;
  final String userId;
  final DateTime date;
  final int completionPercent;

  const GroupProgress({
    required this.id,
    required this.groupId,
    required this.itemId,
    required this.userId,
    required this.date,
    required this.completionPercent,
  });

  factory GroupProgress.fromJson(Map<String, dynamic> json) {
    return GroupProgress(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      completionPercent: json['completion_percent'] as int? ?? 0,
    );
  }
}

class ProofSubmission {
  final String id;
  final String groupId;
  final String itemId;
  final String userId;
  final String date;
  final String proofType;
  final String? imageUrl;
  final String? caption;
  final double? numericValue;
  final String? numericUnit;
  final String status; // pending, approved, rejected
  final int votesApprove;
  final int votesReject;
  final int quorumSize;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  // Optional joined fields
  final String? submitterName;
  final String? submitterAvatar;

  const ProofSubmission({
    required this.id,
    required this.groupId,
    required this.itemId,
    required this.userId,
    required this.date,
    required this.proofType,
    this.imageUrl,
    this.caption,
    this.numericValue,
    this.numericUnit,
    required this.status,
    required this.votesApprove,
    required this.votesReject,
    required this.quorumSize,
    this.resolvedAt,
    required this.createdAt,
    this.submitterName,
    this.submitterAvatar,
  });

  factory ProofSubmission.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ProofSubmission(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] as String,
      proofType: json['proof_type'] as String? ?? 'photo',
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      numericValue: (json['numeric_value'] as num?)?.toDouble(),
      numericUnit: json['numeric_unit'] as String?,
      status: json['status'] as String? ?? 'pending',
      votesApprove: json['votes_approve'] as int? ?? 0,
      votesReject: json['votes_reject'] as int? ?? 0,
      quorumSize: json['quorum_size'] as int? ?? 3,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      submitterName: profile?['display_name'] as String?,
      submitterAvatar: profile?['avatar_url'] as String?,
    );
  }
}
