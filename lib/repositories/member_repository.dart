import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member_group.dart';
import 'package:asv_app/models/member.dart';

class MemberRepository {
  final SupabaseClient supa;
  MemberRepository(this.supa);

  /// Gibt die Member ID für einen User zurück
  Future<int?> findMemberIdForUser(String userId) async {
    final res = await supa.from('member').select('id').eq('user_id', userId).maybeSingle();
    if (res == null) return null;
    return res['id'] as int? ?? (res['id'] as num?)?.toInt();
  }

  /// Gibt die Benutzergruppe für einen User zurück
  Future<MemberGroup> getMemberGroupForUser(String userId) async {
    final res = await supa
        .from('member')
        .select('member_group')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null || !res.containsKey('member_group')) {
      return MemberGroup.aktive; // Default
    }

    return MemberGroup.fromString(res['member_group'] as String?);
  }

  /// Aktualisiert die Benutzergruppe für einen Member
  Future<void> updateMemberGroup(int memberId, MemberGroup group) async {
    await supa
        .from('member')
        .update({'member_group': group.value})
        .eq('id', memberId);
  }

  /// Gibt vollständige Member-Daten für einen User zurück
  Future<Member?> getMemberByUserId(String userId) async {
    try {
      final res = await supa
          .from('member')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return Member.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Gibt Member nach ID zurück
  Future<Member?> getMemberById(int memberId) async {
    try {
      final res = await supa
          .from('member')
          .select('*')
          .eq('id', memberId)
          .maybeSingle();

      if (res == null) return null;
      return Member.fromJson(res);
    } catch (e) {
      return null;
    }
  }

  /// Erstellt einen neuen Member
  Future<Member?> createMember(Member member) async {
    try {
      final response = await supa
          .from('member')
          .insert(member.toJson())
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Aktualisiert Member-Daten
  Future<Member?> updateMember(Member member) async {
    try {
      if (member.id == null) return null;

      final updateData = member.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supa
          .from('member')
          .update(updateData)
          .eq('id', member.id!)
          .select()
          .single();

      return Member.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Aktualisiert nur bestimmte Felder eines Members
  Future<bool> updateMemberFields(int memberId, Map<String, dynamic> fields) async {
    try {
      fields['updated_at'] = DateTime.now().toIso8601String();

      await supa
          .from('member')
          .update(fields)
          .eq('id', memberId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Löscht einen Member (soft delete möglich)
  Future<bool> deleteMember(int memberId) async {
    try {
      await supa.from('member').delete().eq('id', memberId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prüft ob ein Member existiert
  Future<bool> memberExists(String userId) async {
    final member = await getMemberByUserId(userId);
    return member != null;
  }

  /// Aktualisiert das Profilbild
  Future<bool> updateProfileImage(int memberId, String imageUrl) async {
    return await updateMemberFields(memberId, {
      'profile_image_url': imageUrl,
    });
  }

  /// Gibt alle Members einer Gruppe zurück
  Future<List<Member>> getMembersByGroup(MemberGroup group) async {
    try {
      final response = await supa
          .from('member')
          .select('*')
          .eq('member_group', group.value)
          .order('last_name', ascending: true);

      return (response as List).map((e) => Member.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gibt die Anzahl der Members pro Gruppe zurück
  Future<Map<MemberGroup, int>> getMemberCountByGroup() async {
    try {
      final response = await supa
          .from('member')
          .select('member_group');

      final List<dynamic> members = response as List;
      final Map<MemberGroup, int> counts = {
        MemberGroup.jugend: 0,
        MemberGroup.aktive: 0,
        MemberGroup.senioren: 0,
      };

      for (final member in members) {
        final group = MemberGroup.fromString(member['member_group'] as String?);
        counts[group] = (counts[group] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {
        MemberGroup.jugend: 0,
        MemberGroup.aktive: 0,
        MemberGroup.senioren: 0,
      };
    }
  }
}
