enum ProofStatus { pending, approved, rejected }

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
  final ProofStatus status;
  final int votesApprove;
  final int votesReject;
  final int quorumSize;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  // Joined fields
  final String? submitterName;
  final String? submitterAvatar;
  final String? itemTitle;
  final String? itemIcon;
  final int? itemColor;
  final String? groupName;

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
    this.itemTitle,
    this.itemIcon,
    this.itemColor,
    this.groupName,
  });

  factory ProofSubmission.fromJson(Map<String, dynamic> json) {
    // Handle nested joins: json may contain 'profiles', 'group_items', 'groups' objects
    final profile = json['profiles'] as Map<String, dynamic>?;
    final item = json['group_items'] as Map<String, dynamic>?;
    final group = json['groups'] as Map<String, dynamic>?;

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
      status: ProofStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProofStatus.pending,
      ),
      votesApprove: json['votes_approve'] as int? ?? 0,
      votesReject: json['votes_reject'] as int? ?? 0,
      quorumSize: json['quorum_size'] as int? ?? 1,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      submitterName: profile?['display_name'] as String?,
      submitterAvatar: profile?['avatar_url'] as String?,
      itemTitle: item?['title'] as String?,
      itemIcon: item?['icon'] as String?,
      itemColor: (item?['color'] as num?)?.toInt(),
      groupName: group?['name'] as String?,
    );
  }
}

class ProofVote {
  final String id;
  final String proofId;
  final String voterId;
  final bool vote;
  final String? reason;
  final DateTime createdAt;
  final String? voterName;

  const ProofVote({
    required this.id,
    required this.proofId,
    required this.voterId,
    required this.vote,
    this.reason,
    required this.createdAt,
    this.voterName,
  });

  factory ProofVote.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ProofVote(
      id: json['id'] as String,
      proofId: json['proof_id'] as String,
      voterId: json['voter_id'] as String,
      vote: json['vote'] as bool,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      voterName: profile?['display_name'] as String?,
    );
  }
}
