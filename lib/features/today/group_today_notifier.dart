import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../groups/group_model.dart';
import '../proofs/proof_notifier.dart';

class GroupTodayItem {
  final GroupItem item;
  final String groupName;
  final int myPercent;
  final ProofSubmission? myProof;

  const GroupTodayItem({
    required this.item,
    required this.groupName,
    required this.myPercent,
    this.myProof,
  });

  bool get needsProof =>
      item.requiresProof && myProof == null && myPercent < 100;

  bool get proofPending => myProof?.status == 'pending';
  bool get proofApproved => myProof?.status == 'approved';
  bool get proofRejected => myProof?.status == 'rejected';
  bool get isComplete => myPercent >= 100 && (!item.requiresProof || proofApproved);
}

class GroupTodayState {
  final List<GroupTodayItem> items;
  final int pendingValidationCount;
  final bool isLoading;
  final String? error;

  const GroupTodayState({
    this.items = const [],
    this.pendingValidationCount = 0,
    this.isLoading = true,
    this.error,
  });

  GroupTodayState copyWith({
    List<GroupTodayItem>? items,
    int? pendingValidationCount,
    bool? isLoading,
    String? error,
  }) {
    return GroupTodayState(
      items: items ?? this.items,
      pendingValidationCount:
          pendingValidationCount ?? this.pendingValidationCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalItems => items.length;
  int get completedItems => items.where((i) => i.isComplete).length;
}

class GroupTodayNotifier extends StateNotifier<GroupTodayState> {
  final SupabaseClient _client;

  GroupTodayNotifier(this._client) : super(const GroupTodayState()) {
    load();
  }

  String get _userId => _client.auth.currentUser!.id;
  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      // Get my group IDs
      final memberRows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', _userId);

      if ((memberRows as List).isEmpty) {
        state = state.copyWith(items: [], isLoading: false);
        return;
      }

      final groupIds =
          memberRows.map((r) => r['group_id'] as String).toList();

      // Fetch groups for names
      final groupRows = await _client
          .from('groups')
          .select('id, name')
          .inFilter('id', groupIds);
      final groupNames = <String, String>{};
      for (final g in groupRows as List) {
        groupNames[g['id'] as String] = g['name'] as String;
      }

      // Fetch all group items
      final itemRows = await _client
          .from('group_items')
          .select()
          .inFilter('group_id', groupIds)
          .order('sort_order');

      final items = (itemRows as List)
          .map((r) => GroupItem.fromJson(r as Map<String, dynamic>))
          .toList();

      if (items.isEmpty) {
        state = state.copyWith(items: [], isLoading: false);
        return;
      }

      // Fetch my progress for today
      final progressRows = await _client
          .from('group_progress')
          .select()
          .eq('user_id', _userId)
          .eq('date', _todayStr)
          .inFilter(
              'item_id', items.map((i) => i.id).toList());

      final myProgress = <String, int>{};
      for (final p in progressRows as List) {
        myProgress[p['item_id'] as String] =
            p['completion_percent'] as int? ?? 0;
      }

      // Fetch my proofs for today
      final proofRows = await _client
          .from('proof_submissions')
          .select()
          .eq('user_id', _userId)
          .eq('date', _todayStr)
          .inFilter(
              'item_id', items.map((i) => i.id).toList());

      final myProofs = <String, ProofSubmission>{};
      for (final p in proofRows as List) {
        final proof =
            ProofSubmission.fromJson(p as Map<String, dynamic>);
        myProofs[proof.itemId] = proof;
      }

      // Build GroupTodayItems
      final todayItems = items.map((item) {
        return GroupTodayItem(
          item: item,
          groupName: groupNames[item.groupId] ?? '',
          myPercent: myProgress[item.id] ?? 0,
          myProof: myProofs[item.id],
        );
      }).toList();

      state = state.copyWith(
        items: todayItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() => load();
}

final groupTodayProvider =
    StateNotifierProvider<GroupTodayNotifier, GroupTodayState>((ref) {
  return GroupTodayNotifier(Supabase.instance.client);
});
