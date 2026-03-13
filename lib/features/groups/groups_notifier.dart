import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  GroupsNotifier(this._supabase) : super(const GroupsState()) {
    _loadGroups();
    _subscribeRealtime();
  }

  String get _uid => _supabase.auth.currentUser!.id;

  Future<void> _loadGroups() async {
    try {
      // Get all group IDs where the current user is a member
      final memberRows = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', _uid);

      if (memberRows.isEmpty) {
        state = state.copyWith(groups: [], isLoading: false);
        return;
      }

      final groupIds =
          (memberRows as List).map((r) => r['group_id'] as String).toList();

      // Fetch full group data
      final groupRows = await _supabase
          .from('groups')
          .select()
          .inFilter('id', groupIds)
          .order('created_at', ascending: false);

      // For each group, fetch member count
      final groups = <Group>[];
      for (final row in groupRows) {
        final membersData = await _supabase
            .from('group_members')
            .select('user_id, role, joined_at, profiles(display_name, avatar_url)')
            .eq('group_id', row['id'] as String);

        final members = (membersData as List)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();

        groups.add(Group.fromJson(row as Map<String, dynamic>, members: members));
      }

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribeRealtime() {
    _channel = _supabase
        .channel('groups_membership')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _uid,
          ),
          callback: (payload) => _loadGroups(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'groups',
          callback: (payload) => _loadGroups(),
        )
        .subscribe();
  }

  /// Creates a new group with a unique 6-char invite code.
  Future<String?> createGroup(String name, {String? description}) async {
    try {
      final code = _generateCode();
      final response = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'description': description,
            'invite_code': code,
            'created_by': _uid,
          })
          .select()
          .single();

      final groupId = response['id'] as String;

      // The DB trigger should auto-add the creator as admin.
      // If there's no trigger, insert manually:
      await _supabase.from('group_members').upsert({
        'group_id': groupId,
        'user_id': _uid,
        'role': 'admin',
      });

      await _loadGroups();
      return groupId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Joins a group by invite code. Returns groupId on success, null on failure.
  Future<String?> joinGroup(String code) async {
    try {
      final rows = await _supabase
          .from('groups')
          .select()
          .eq('invite_code', code.trim().toUpperCase())
          .limit(1);

      if ((rows as List).isEmpty) {
        state = state.copyWith(
            error: 'Group not found. Check the code and try again.');
        return null;
      }

      final group = rows.first as Map<String, dynamic>;
      final groupId = group['id'] as String;

      // Check if already a member
      final existing = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('user_id', _uid)
          .maybeSingle();

      if (existing != null) {
        // Already a member
        return groupId;
      }

      // Check max members
      final memberCount = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);
      final maxMembers = group['max_members'] as int? ?? 20;
      if ((memberCount as List).length >= maxMembers) {
        state = state.copyWith(error: 'This group is full.');
        return null;
      }

      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': _uid,
        'role': 'member',
      });

      await _loadGroups();
      return groupId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Leaves a group.
  Future<void> leaveGroup(String groupId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', _uid);

      await _loadGroups();
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

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(Supabase.instance.client);
});
