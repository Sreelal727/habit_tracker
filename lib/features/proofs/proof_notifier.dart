import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'proof_model.dart';

class ProofNotifierState {
  final List<ProofSubmission> pendingValidations;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const ProofNotifierState({
    this.pendingValidations = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  ProofNotifierState copyWith({
    List<ProofSubmission>? pendingValidations,
    bool? isLoading,
    bool? isUploading,
    String? error,
  }) {
    return ProofNotifierState(
      pendingValidations: pendingValidations ?? this.pendingValidations,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

class ProofNotifier extends StateNotifier<ProofNotifierState> {
  final SupabaseClient _client;

  ProofNotifier(this._client) : super(const ProofNotifierState()) {
    _loadPendingValidations();
  }

  String get _userId => _client.auth.currentUser!.id;

  Future<void> _loadPendingValidations() async {
    state = state.copyWith(isLoading: true);
    try {
      // Get my group IDs
      final memberRows = await _client
          .from('group_members')
          .select('group_id')
          .eq('user_id', _userId);
      final groupIds =
          (memberRows as List).map((r) => r['group_id'] as String).toList();

      if (groupIds.isEmpty) {
        state = state.copyWith(pendingValidations: [], isLoading: false);
        return;
      }

      // Get pending proofs in my groups, not mine
      final rows = await _client
          .from('proof_submissions')
          .select(
            '*, profiles!proof_submissions_user_id_fkey(display_name, avatar_url), '
            'group_items!inner(title, icon, color), groups!inner(name)',
          )
          .inFilter('group_id', groupIds)
          .neq('user_id', _userId)
          .eq('status', 'pending')
          .order('created_at');

      final proofs =
          (rows as List).map((r) => ProofSubmission.fromJson(r)).toList();

      // Filter out proofs I've already voted on
      final votedRows = await _client
          .from('proof_votes')
          .select('proof_id')
          .eq('voter_id', _userId);
      final votedProofIds =
          (votedRows as List).map((r) => r['proof_id'] as String).toSet();

      final unvoted =
          proofs.where((p) => !votedProofIds.contains(p.id)).toList();

      state = state.copyWith(pendingValidations: unvoted, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ProofSubmission?> submitProof({
    required String groupId,
    required String itemId,
    required String proofType,
    File? imageFile,
    String? caption,
    double? numericValue,
    String? numericUnit,
  }) async {
    state = state.copyWith(isUploading: true, error: null);
    try {
      String? imageUrl;

      if (imageFile != null) {
        final ext = imageFile.path.split('.').last;
        final path = '$_userId/${const Uuid().v4()}.$ext';
        await _client.storage.from('proofs').upload(path, imageFile);
        imageUrl = _client.storage.from('proofs').getPublicUrl(path);
      }

      // Calculate quorum based on group member count
      final memberCount = await _client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);
      final count = (memberCount as List).length;
      final quorum = count <= 2 ? 1 : (count / 2).ceil() - 1;

      final today = DateTime.now().toIso8601String().substring(0, 10);

      final row = await _client
          .from('proof_submissions')
          .upsert(
            {
              'group_id': groupId,
              'item_id': itemId,
              'user_id': _userId,
              'date': today,
              'proof_type': proofType,
              'image_url': imageUrl,
              'caption': caption,
              'numeric_value': numericValue,
              'numeric_unit': numericUnit,
              'status': 'pending',
              'quorum_size': quorum.clamp(1, 10),
            },
            onConflict: 'item_id,user_id,date',
          )
          .select()
          .single();

      state = state.copyWith(isUploading: false);
      return ProofSubmission.fromJson(row);
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return null;
    }
  }

  Future<void> vote(String proofId, bool approve, {String? reason}) async {
    try {
      await _client.from('proof_votes').insert({
        'proof_id': proofId,
        'voter_id': _userId,
        'vote': approve,
        'reason': reason,
      });

      // Remove from local list
      state = state.copyWith(
        pendingValidations:
            state.pendingValidations.where((p) => p.id != proofId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<ProofVote>> getVotes(String proofId) async {
    final rows = await _client
        .from('proof_votes')
        .select('*, profiles!proof_votes_voter_id_fkey(display_name)')
        .eq('proof_id', proofId);
    return (rows as List).map((r) => ProofVote.fromJson(r)).toList();
  }

  void refresh() => _loadPendingValidations();
}

final proofProvider =
    StateNotifierProvider<ProofNotifier, ProofNotifierState>((ref) {
  return ProofNotifier(Supabase.instance.client);
});

// Pending validation count for badges
final pendingValidationCountProvider = Provider<int>((ref) {
  return ref.watch(proofProvider).pendingValidations.length;
});
