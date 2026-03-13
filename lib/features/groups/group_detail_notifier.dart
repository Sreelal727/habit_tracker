import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'group_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class GroupDetailState {
  final Group? group;
  final List<GroupItem> items;
  /// { itemId → { uid → GroupProgress } }
  final Map<String, Map<String, GroupProgress>> todayProgress;
  final bool isLoading;
  final String? error;

  const GroupDetailState({
    this.group,
    this.items = const [],
    this.todayProgress = const {},
    this.isLoading = true,
    this.error,
  });

  GroupDetailState copyWith({
    Group? group,
    List<GroupItem>? items,
    Map<String, Map<String, GroupProgress>>? todayProgress,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GroupDetailState(
      group: group ?? this.group,
      items: items ?? this.items,
      todayProgress: todayProgress ?? this.todayProgress,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GroupDetailNotifier extends StateNotifier<GroupDetailState> {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String groupId;

  StreamSubscription? _groupSub;
  StreamSubscription? _itemsSub;
  StreamSubscription? _progressSub;

  GroupDetailNotifier(this._db, this._auth, this.groupId)
      : super(const GroupDetailState()) {
    _subscribe();
  }

  String get _uid => _auth.currentUser!.uid;
  String get _displayName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'User';
  String get _todayStr =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  void _subscribe() {
    // Group doc
    _groupSub = _db.collection('groups').doc(groupId).snapshots().listen(
      (snap) {
        if (!snap.exists) return;
        state = state.copyWith(group: Group.fromDoc(snap), isLoading: false);
      },
      onError: (e) => state = state.copyWith(isLoading: false, error: e.toString()),
    );

    // Items subcollection
    _itemsSub = _db
        .collection('groups')
        .doc(groupId)
        .collection('items')
        .orderBy('addedAt')
        .snapshots()
        .listen(
      (snap) {
        final items = snap.docs.map((d) => GroupItem.fromDoc(d, groupId)).toList();
        state = state.copyWith(items: items);
      },
    );

    // Today's progress
    _progressSub = _db
        .collection('groups')
        .doc(groupId)
        .collection('progress')
        .where('date', isEqualTo: _todayStr)
        .snapshots()
        .listen(
      (snap) {
        final Map<String, Map<String, GroupProgress>> progress = {};
        for (final doc in snap.docs) {
          final p = GroupProgress.fromDoc(doc);
          progress.putIfAbsent(p.itemId, () => {})[p.uid] = p;
        }
        state = state.copyWith(todayProgress: progress);
      },
    );
  }

  /// Adds a shared habit or goal to the group.
  Future<void> addItem({
    required String type,
    required String title,
    required String icon,
    required int color,
  }) async {
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('items')
          .add({
        'type': type,
        'title': title,
        'icon': icon,
        'color': color,
        'addedBy': _uid,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Updates the current user's completion percent for an item today.
  Future<void> updateProgress(String itemId, int percent) async {
    try {
      final docId = '${_uid}_${_todayStr}_$itemId';
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('progress')
          .doc(docId)
          .set({
        'uid': _uid,
        'userName': _displayName,
        'groupId': groupId,
        'itemId': itemId,
        'date': _todayStr,
        'completionPercent': percent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Removes an item from the group (only creator or item adder).
  Future<void> removeItem(String itemId) async {
    try {
      await _db
          .collection('groups')
          .doc(groupId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// My completion percent for a given item today.
  int myPercent(String itemId) =>
      state.todayProgress[itemId]?[_uid]?.completionPercent ?? 0;

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _groupSub?.cancel();
    _itemsSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groupDetailProvider = StateNotifierProvider.family<
    GroupDetailNotifier, GroupDetailState, String>((ref, groupId) {
  return GroupDetailNotifier(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    groupId,
  );
});
