import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, String> members; // uid -> displayName

  Group({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.members,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] as String,
      inviteCode: data['inviteCode'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      members: Map<String, String>.from(data['members'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'inviteCode': inviteCode,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'members': members,
      };
}

class GroupItem {
  final String id;
  final String groupId;
  final String type; // 'habit' | 'goal'
  final String title;
  final String icon; // icon key string
  final int color;
  final String addedBy;
  final DateTime addedAt;

  GroupItem({
    required this.id,
    required this.groupId,
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.addedBy,
    required this.addedAt,
  });

  factory GroupItem.fromDoc(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupItem(
      id: doc.id,
      groupId: groupId,
      type: data['type'] as String,
      title: data['title'] as String,
      icon: data['icon'] as String? ?? 'star',
      color: data['color'] as int,
      addedBy: data['addedBy'] as String,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'icon': icon,
        'color': color,
        'addedBy': addedBy,
        'addedAt': Timestamp.fromDate(addedAt),
      };
}

class GroupProgress {
  final String uid;
  final String userName;
  final String groupId;
  final String itemId;
  final String date; // YYYY-MM-DD
  final int completionPercent;
  final DateTime updatedAt;

  GroupProgress({
    required this.uid,
    required this.userName,
    required this.groupId,
    required this.itemId,
    required this.date,
    required this.completionPercent,
    required this.updatedAt,
  });

  factory GroupProgress.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupProgress(
      uid: data['uid'] as String,
      userName: data['userName'] as String? ?? 'Member',
      groupId: data['groupId'] as String,
      itemId: data['itemId'] as String,
      date: data['date'] as String,
      completionPercent: data['completionPercent'] as int? ?? 0,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'userName': userName,
        'groupId': groupId,
        'itemId': itemId,
        'date': date,
        'completionPercent': completionPercent,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
