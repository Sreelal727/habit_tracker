import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'group_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class GroupsState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  const GroupsState({
    this.groups = const [],
    this.isLoading = true,
    this.error,
  });

  GroupsState copyWith({
    List<Group>? groups,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GroupsNotifier extends StateNotifier<GroupsState> {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  GroupsNotifier(this._db, this._auth) : super(const GroupsState()) {
    _loadGroups();
  }

  String get _uid => _auth.currentUser!.uid;
  String get _displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'User';

  void _loadGroups() {
    _db
        .collection('groups')
        .where('memberUids', arrayContains: _uid)
        .snapshots()
        .listen((snap) {
      final groups = snap.docs.map((d) => Group.fromDoc(d)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(groups: groups, isLoading: false);
    }, onError: (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    });
  }

  /// Creates a new group with a unique 6-char invite code.
  Future<String?> createGroup(String name) async {
    try {
      final code = _generateCode();
      final ref = _db.collection('groups').doc();
      await ref.set({
        'name': name,
        'inviteCode': code,
        'createdBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': {_uid: _displayName},
        'memberUids': [_uid],
      });
      return ref.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Joins a group by invite code. Returns groupId on success, null on failure.
  Future<String?> joinGroup(String code) async {
    try {
      final snap = await _db
          .collection('groups')
          .where('inviteCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        state = state.copyWith(error: 'Group not found. Check the code and try again.');
        return null;
      }

      final doc = snap.docs.first;
      final members = Map<String, dynamic>.from(doc.data()['members'] as Map? ?? {});
      if (members.containsKey(_uid)) {
        // Already a member
        return doc.id;
      }

      await doc.reference.update({
        'members.$_uid': _displayName,
        'memberUids': FieldValue.arrayUnion([_uid]),
      });
      return doc.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Leaves a group.
  Future<void> leaveGroup(String groupId) async {
    try {
      await _db.collection('groups').doc(groupId).update({
        'members.$_uid': FieldValue.delete(),
        'memberUids': FieldValue.arrayRemove([_uid]),
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});
