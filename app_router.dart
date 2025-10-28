import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/catch_create_screen.dart';
import 'features/catches/catch_list_screen.dart';
import 'features/catches/catch_detail_screen.dart';
import 'features/events/event_list_screen.dart';
import 'features/events/event_detail_screen.dart';
import 'features/ranking/ranking_shell_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/admin/export_panel.dart';
import 'features/admin/member_group_admin_screen.dart';
import 'features/admin/admin_announcement_screen.dart';
import 'features/notifications/notifications_screen.dart';

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
    GoRoute(path: '/catches', builder: (_, __) => const CatchListScreen()),
    GoRoute(
      path: '/catch/:id',
      builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return CatchDetailScreen(catchId: id);
      },
    ),
    GoRoute(path: '/catch/new', builder: (_, __) => const CatchCreateScreen()),
    GoRoute(path: '/events', builder: (_, __) => const EventListScreen()),
    GoRoute(
      path: '/events/:id',
      builder: (_, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EventDetailScreen(eventId: id);
      },
    ),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/admin/export', builder: (_, __) => const ExportPanel()),
    GoRoute(path: '/admin/member-groups', builder: (_, __) => const MemberGroupAdminScreen()),
    GoRoute(path: '/admin/announcements', builder: (_, __) => const AdminAnnouncementScreen()),
  ],
);
