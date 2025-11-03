import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/catch_create_screen.dart';
import 'features/ranking/ranking_shell_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/admin/export_panel.dart';
import 'features/admin/member_group_admin_screen.dart';
import 'features/admin/admin_announcement_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/notifications/notification_settings_screen.dart';
import 'features/weather/weather_bite_screen.dart';
import 'features/social/instagram_feed_screen.dart';

/// Hält GoRouter in sync mit Supabase-Auth-Events
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }
}
final _authListenable = _AuthListenable();

final appRouter = GoRouter(
  initialLocation: '/',                // Splash deaktiviert
  refreshListenable: _authListenable,  // bei Login/Logout neu entscheiden
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.subloc == '/auth';
    if (session == null) return isAuthRoute ? null : '/auth';
    if (isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const SignInScreen()),
    GoRoute(path: '/auth/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/ranking', builder: (_, __) => const RankingShellScreen()),
    GoRoute(path: '/catch/new', builder: (_, __) => const CatchCreateScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/notifications/settings', builder: (_, __) => const NotificationSettingsScreen()),
    GoRoute(path: '/weather', builder: (_, __) => const WeatherBiteScreen()),
    GoRoute(path: '/instagram', builder: (_, __) => const InstagramFeedScreen()),
    GoRoute(path: '/admin/export', builder: (_, __) => const ExportPanel()),
    GoRoute(path: '/admin/member-groups', builder: (_, __) => const MemberGroupAdminScreen()),
    GoRoute(path: '/admin/announcements', builder: (_, __) => const AdminAnnouncementScreen()),
  ],
);
