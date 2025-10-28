import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:asv_app/models/member_group.dart';

/// Provider für die aktuelle Benutzergruppe
class MemberGroupNotifier extends StateNotifier<MemberGroup?> {
  MemberGroupNotifier() : super(null);

  /// Lädt die Benutzergruppe für den aktuellen User
  Future<void> loadMemberGroup() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = null;
        return;
      }

      // Versuche zuerst aus user_metadata zu lesen
      final metadata = user.userMetadata;
      if (metadata != null && metadata.containsKey('member_group')) {
        state = MemberGroup.fromString(metadata['member_group'] as String?);
        return;
      }

      // Falls nicht in Metadata, versuche aus member Tabelle zu lesen
      final response = await Supabase.instance.client
          .from('member')
          .select('member_group')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response.containsKey('member_group')) {
        state = MemberGroup.fromString(response['member_group'] as String?);
      } else {
        // Fallback: Aktive
        state = MemberGroup.aktive;
      }
    } catch (e) {
      // Bei Fehler: Aktive als Standard
      state = MemberGroup.aktive;
    }
  }

  /// Setzt die Benutzergruppe manuell (für Testing/Admin)
  void setMemberGroup(MemberGroup group) {
    state = group;
  }

  /// Setzt die Gruppe zurück
  void reset() {
    state = null;
  }
}

/// Global Provider für die Benutzergruppe
final memberGroupProvider = StateNotifierProvider<MemberGroupNotifier, MemberGroup?>((ref) {
  return MemberGroupNotifier();
});
