import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/ranking/ranking_shell_screen.dart';
import 'features/auth/sign_in_screen.dart';

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
    GoRoute(path: '/ranking', builder: (_, __) => const RankingShellScreen()),
    GoRoute(path: '/catch/new', builder: (_, __) => const CatchCreateScreen()), // kommt unten
  ],
);
