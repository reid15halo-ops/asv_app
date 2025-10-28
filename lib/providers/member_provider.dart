import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member.dart';
import 'package:asv_app/repositories/member_repository.dart';

/// Provider für MemberRepository
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(Supabase.instance.client);
});

/// Provider für aktuell eingeloggten Member
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final repository = ref.read(memberRepositoryProvider);
  return await repository.getMemberByUserId(user.id);
});

/// StateNotifier für Member-Management
class MemberNotifier extends StateNotifier<AsyncValue<Member?>> {
  MemberNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadCurrentMember();
  }

  final MemberRepository repository;

  /// Lädt den aktuell eingeloggten Member
  Future<void> loadCurrentMember() async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final member = await repository.getMemberByUserId(user.id);
      state = AsyncValue.data(member);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Aktualisiert Member-Daten
  Future<bool> updateMember(Member member) async {
    try {
      final updated = await repository.updateMember(member);
      if (updated != null) {
        state = AsyncValue.data(updated);
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Aktualisiert einzelne Felder
  Future<bool> updateFields(int memberId, Map<String, dynamic> fields) async {
    try {
      final success = await repository.updateMemberFields(memberId, fields);
      if (success) {
        await loadCurrentMember(); // Reload nach Update
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Erstellt einen neuen Member
  Future<Member?> createMember(Member member) async {
    try {
      final created = await repository.createMember(member);
      if (created != null) {
        state = AsyncValue.data(created);
      }
      return created;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Aktualisiert das Profilbild
  Future<bool> updateProfileImage(int memberId, String imageUrl) async {
    try {
      final success = await repository.updateProfileImage(memberId, imageUrl);
      if (success) {
        await loadCurrentMember();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Refresh Member-Daten
  Future<void> refresh() async {
    await loadCurrentMember();
  }
}

/// Provider für MemberNotifier
final memberNotifierProvider = StateNotifierProvider<MemberNotifier, AsyncValue<Member?>>((ref) {
  final repository = ref.watch(memberRepositoryProvider);
  return MemberNotifier(repository);
});
