import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'milestone_model.dart';

class MilestoneState {
  final List<MilestoneDefinition> definitions;
  final Map<String, UserMilestone> progress; // milestoneId -> UserMilestone
  final List<String> recentlyCompleted; // milestone IDs just completed
  final bool isLoading;
  final String? error;

  const MilestoneState({
    this.definitions = const [],
    this.progress = const {},
    this.recentlyCompleted = const [],
    this.isLoading = false,
    this.error,
  });

  MilestoneState copyWith({
    List<MilestoneDefinition>? definitions,
    Map<String, UserMilestone>? progress,
    List<String>? recentlyCompleted,
    bool? isLoading,
    String? error,
  }) {
    return MilestoneState(
      definitions: definitions ?? this.definitions,
      progress: progress ?? this.progress,
      recentlyCompleted: recentlyCompleted ?? this.recentlyCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Milestones in progress (started but not completed).
  List<MilestoneDefinition> get inProgress {
    return definitions.where((d) {
      final p = progress[d.id];
      return p != null && !p.completed && p.currentValue > 0;
    }).toList();
  }

  /// Milestones that are completed.
  List<MilestoneDefinition> get completed {
    return definitions.where((d) {
      final p = progress[d.id];
      return p != null && p.completed;
    }).toList();
  }

  /// Milestones not yet started.
  List<MilestoneDefinition> get notStarted {
    return definitions.where((d) {
      final p = progress[d.id];
      return p == null || (!p.completed && p.currentValue == 0);
    }).toList();
  }
}

class MilestoneNotifier extends StateNotifier<MilestoneState> {
  final SupabaseClient _client;

  MilestoneNotifier(this._client) : super(const MilestoneState()) {
    loadAll();
  }

  String get _userId => _client.auth.currentUser!.id;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      // Fetch all milestone definitions
      final defRows = await _client
          .from('milestone_definitions')
          .select()
          .order('sort_order');
      final definitions = (defRows as List)
          .map((r) => MilestoneDefinition.fromJson(r))
          .toList();

      // Fetch user's milestone progress with joined definitions
      final progressRows = await _client
          .from('user_milestones')
          .select('*, milestone_definitions(*)')
          .eq('user_id', _userId);

      final progressMap = <String, UserMilestone>{};
      for (final row in (progressRows as List)) {
        final um = UserMilestone.fromJson(row);
        progressMap[um.milestoneId] = um;
      }

      // Check for newly completed milestones
      final previousProgress = state.progress;
      final newlyCompleted = <String>[];
      for (final entry in progressMap.entries) {
        if (entry.value.completed) {
          final prev = previousProgress[entry.key];
          if (prev == null || !prev.completed) {
            newlyCompleted.add(entry.key);
          }
        }
      }

      state = state.copyWith(
        definitions: definitions,
        progress: progressMap,
        recentlyCompleted: newlyCompleted,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> claimReward(String milestoneId) async {
    final milestone = state.progress[milestoneId];
    if (milestone == null || !milestone.completed || milestone.coinsClaimed) {
      return false;
    }

    try {
      await _client
          .from('user_milestones')
          .update({'coins_claimed': true})
          .eq('user_id', _userId)
          .eq('milestone_id', milestoneId);

      // Update local state
      final updatedProgress = Map<String, UserMilestone>.from(state.progress);
      final def = milestone.definition;
      updatedProgress[milestoneId] = UserMilestone(
        id: milestone.id,
        userId: milestone.userId,
        milestoneId: milestone.milestoneId,
        currentValue: milestone.currentValue,
        completed: true,
        completedAt: milestone.completedAt,
        coinsClaimed: true,
        definition: def,
      );

      state = state.copyWith(progress: updatedProgress);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear recently completed list (after showing celebration).
  void clearRecentlyCompleted() {
    state = state.copyWith(recentlyCompleted: []);
  }

  void refresh() => loadAll();
}

final milestoneProvider =
    StateNotifierProvider<MilestoneNotifier, MilestoneState>((ref) {
  return MilestoneNotifier(Supabase.instance.client);
});
