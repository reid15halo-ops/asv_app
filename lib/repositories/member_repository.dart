import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member_group.dart';

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
}
