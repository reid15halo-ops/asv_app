import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));

  late final Animation<double> _youthFade =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
  late final Animation<double> _youthScale =
      Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
      );

  late final Animation<double> _clubFade =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.95, curve: Curves.easeOut));
  late final Animation<double> _clubScale =
      Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.95, curve: Curves.easeOutBack)),
      );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        context.go('/'); // nach 3s zum Dashboard
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Jugend-Logo (zuerst, leicht kleiner)
                Transform.scale(
                  scale: _youthScale.value,
                  child: Opacity(
                    opacity: _youthFade.value,
                    child: Image.asset(
                      'assets/logos/jugend_logo.png',
                      width: 220,
                      fit: BoxFit.contain,
                      // >>> robust gegen fehlende/ungültige Assets:
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 220, height: 120),
                    ),
                  ),
                ),

                // Vereinslogo (darüber, etwas größer)
                Transform.scale(
                  scale: _clubScale.value,
                  child: Opacity(
                    opacity: _clubFade.value,
                    child: Image.asset(
                      'assets/logos/asv_logo.png',
                      width: 260,
                      fit: BoxFit.contain,
                      // >>> robust gegen fehlende/ungültige Assets:
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 260, height: 140),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
