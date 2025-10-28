import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'app_router.dart';
import 'theme/theme.dart';
import 'providers/member_group_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
  runApp(const ProviderScope(child: ASVApp()));
}

class ASVApp extends ConsumerWidget {
  const ASVApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Beobachte die aktuelle Benutzergruppe
    final memberGroup = ref.watch(memberGroupProvider);

    return MaterialApp.router(
      title: 'ASV Großostheim',
      routerConfig: appRouter,
      theme: buildLightTheme(memberGroup),
      darkTheme: buildDarkTheme(memberGroup),
      themeMode: ThemeMode.system,
    );
  }
}
