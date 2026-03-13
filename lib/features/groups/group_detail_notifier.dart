import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_model.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class GroupDetailState {
  final Group? group;
  final List<GroupItem> items;

  /// { itemId -> { userId -> GroupProgress } }
  final Map<String, Map<String, GroupProgress>> progress;

  /// { itemId -> my proof for today }
  final Map<String, ProofSubmission> myProofs;

  /// { itemId -> all pending proofs }
  final Map<String, List<ProofSubmission>> pendingProofs;

  final bool isLoading;
  final String? error;

  const GroupDetailState({
    this.group,
    this.items = const [],
    this.progress = const {},
    this.myProofs = const {},
    this.pendingProofs = const {},
    this.isLoading = true,
    this.error,
  });

  GroupDetailState copyWith({
    Group? group,
    List<GroupItem>? items,
    Map<String, Map<String, GroupProgress>>? progress,
    Map<String, ProofSubmission>? myProofs,
    Map<String, List<ProofSubmission>>? pendingProofs,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GroupDetailState(
      group: group ?? this.group,
      items: items ?? this.items,
      progress: progress ?? this.progress,
      myProofs: myProofs ?? this.myProofs,
      pendingProofs: pendingProofs ?? this.pendingProofs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class GroupDetailNotifier extends StateNotifier<GroupDetailState> {
  final SupabaseClient _supabase;
  final String groupId;

  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _progressChannel;
  RealtimeChannel? _proofsChannel;

  GroupDetailNotifier(this._supabase, this.groupId)
      : super(const GroupDetailState()) {
    _loadAll();
    _subscribeRealtime();
  }

  String get _uid => _supabase.auth.currentUser!.id;
  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        _loadGroup(),
        _loadItems(),
        _loadProgress(),
        _loadProofs(),
      ]);
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> _loadGroup() async {
    final groupRow = await _supabase
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();

    final membersData = await _supabase
        .from('group_members')
        .select('user_id, role, joined_at, profiles(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('joined_at');

    final members = (membersData as List)
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList();

    if (mounted) {
      state = state.copyWith(
        group: Group.fromJson(groupRow as Map<String, dynamic>, members: members),
      );
    }
  }

  Future<void> _loadItems() async {
    final rows = await _supabase
        .from('group_items')
        .select()
        .eq('group_id', groupId)
        .order('sort_order')
        .order('created_at');

    final items = (rows as List)
        .map((r) => GroupItem.fromJson(r as Map<String, dynamic>))
        .toList();

    if (mounted) {
      state = state.copyWith(items: items);
    }
  }

  Future<void> _loadProgress() async {
    final rows = await _supabase
        .from('group_progress')
        .select()
        .eq('group_id', groupId)
        .eq('date', _todayStr);

    final Map<String, Map<String, GroupProgress>> progressMap = {};
    for (final row in rows as List) {
      final p = GroupProgress.fromJson(row as Map<String, dynamic>);
      progressMap.putIfAbsent(p.itemId, () => {})[p.userId] = p;
    }

    if (mounted) {
      state = state.copyWith(progress: progressMap);
    }
  }

  Future<void> _loadProofs() async {
    // Load my proofs for today
    final myRows = await _supabase
        .from('proof_submissions')
        .select('*, profiles(display_name, avatar_url)')
        .eq('group_id', groupId)
        .eq('user_id', _uid)
        .eq('date', _todayStr);

    final Map<String, ProofSubmission> myProofs = {};
    for (final row in myRows as List) {
      final proof = ProofSubmission.fromJson(row as Map<String, dynamic>);
      myProofs[proof.itemId] = proof;
    }

    // Load all pending proofs for today
    final pendingRows = await _supabase
        .from('proof_submissions')
        .select('*, profiles(display_name, avatar_url)')
        .eq('group_id', groupId)
        .eq('date', _todayStr)
        .eq('status', 'pending');

    final Map<String, List<ProofSubmission>> pendingProofs = {};
    for (final row in pendingRows as List) {
      final proof = ProofSubmission.fromJson(row as Map<String, dynamic>);
      pendingProofs.putIfAbsent(proof.itemId, () => []).add(proof);
    }

    if (mounted) {
      state = state.copyWith(myProofs: myProofs, pendingProofs: pendingProofs);
    }
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  void _subscribeRealtime() {
    _itemsChannel = _supabase
        .channel('group_items_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _loadItems(),
        )
        .subscribe();

    _progressChannel = _supabase
        .channel('group_progress_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_progress',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _loadProgress(),
        )
        .subscribe();

    _proofsChannel = _supabase
        .channel('group_proofs_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'proof_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (_) => _loadProofs(),
        )
        .subscribe();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Adds a shared habit or goal to the group.
  Future<void> addItem({
    required String type,
    required String title,
    String? description,
    required String icon,
    required int color,
    bool requiresProof = true,
    String proofType = 'photo',
    String? proofDescription,
  }) async {
    try {
      await _supabase.from('group_items').insert({
        'group_id': groupId,
        'type': type,
        'title': title,
        'description': description,
        'icon': icon,
        'color': color,
        'requires_proof': requiresProof,
        'proof_type': proofType,
        'proof_description': proofDescription,
        'sort_order': state.items.length,
        'added_by': _uid,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Updates the current user's completion percent for an item today.
  Future<void> updateProgress(String itemId, int percent) async {
    try {
      await _supabase.from('group_progress').upsert(
        {
          'group_id': groupId,
          'item_id': itemId,
          'user_id': _uid,
          'date': _todayStr,
          'completion_percent': percent,
        },
        onConflict: 'item_id,user_id,date',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Submits proof for an item today.
  Future<void> submitProof({
    required String itemId,
    required String proofType,
    String? imageUrl,
    String? caption,
    double? numericValue,
    String? numericUnit,
  }) async {
    try {
      // Calculate quorum: majority of members (at least 1)
      final memberCount = state.group?.members.length ?? 1;
      final quorum = (memberCount / 2).ceil().clamp(1, memberCount);

      await _supabase.from('proof_submissions').upsert(
        {
          'group_id': groupId,
          'item_id': itemId,
          'user_id': _uid,
          'date': _todayStr,
          'proof_type': proofType,
          'image_url': imageUrl,
          'caption': caption,
          'numeric_value': numericValue,
          'numeric_unit': numericUnit,
          'status': 'pending',
          'votes_approve': 0,
          'votes_reject': 0,
          'quorum_size': quorum,
        },
        onConflict: 'item_id,user_id,date',
      );

      // Auto-set progress to 100% when proof is submitted
      await updateProgress(itemId, 100);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Vote on a proof submission.
  Future<void> voteOnProof(String proofId, bool approve, {String? reason}) async {
    try {
      await _supabase.from('proof_votes').upsert(
        {
          'proof_id': proofId,
          'voter_id': _uid,
          'vote': approve,
          'reason': reason,
        },
        onConflict: 'proof_id,voter_id',
      );

      // Update vote counts on the proof submission
      final votes = await _supabase
          .from('proof_votes')
          .select('vote')
          .eq('proof_id', proofId);

      int approveCount = 0;
      int rejectCount = 0;
      for (final v in votes as List) {
        if (v['vote'] == true) {
          approveCount++;
        } else {
          rejectCount++;
        }
      }

      final updateData = <String, dynamic>{
        'votes_approve': approveCount,
        'votes_reject': rejectCount,
      };

      // Get the proof to check quorum
      final proof = await _supabase
          .from('proof_submissions')
          .select('quorum_size')
          .eq('id', proofId)
          .single();

      final quorum = proof['quorum_size'] as int? ?? 3;
      if (approveCount >= quorum) {
        updateData['status'] = 'approved';
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      } else if (rejectCount >= quorum) {
        updateData['status'] = 'rejected';
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('proof_submissions')
          .update(updateData)
          .eq('id', proofId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Removes an item from the group.
  Future<void> removeItem(String itemId) async {
    try {
      await _supabase.from('group_items').delete().eq('id', itemId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// My completion percent for a given item today.
  int myPercent(String itemId) =>
      state.progress[itemId]?[_uid]?.completionPercent ?? 0;

  /// My proof for a given item today.
  ProofSubmission? myProof(String itemId) => state.myProofs[itemId];

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _itemsChannel?.unsubscribe();
    _progressChannel?.unsubscribe();
    _proofsChannel?.unsubscribe();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groupDetailProvider = StateNotifierProvider.family<GroupDetailNotifier,
    GroupDetailState, String>((ref, groupId) {
  return GroupDetailNotifier(Supabase.instance.client, groupId);
});
