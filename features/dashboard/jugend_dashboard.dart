import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:asv_app/widgets/jugend_widgets.dart';
import 'package:asv_app/theme/theme.dart';
import 'package:asv_app/providers/gamification_provider.dart';
import 'package:asv_app/providers/notification_provider.dart';

/// Spezielles Dashboard für Jugend mit modernem Design und Gamification
class JugendDashboard extends ConsumerStatefulWidget {
  const JugendDashboard({super.key});

  @override
  ConsumerState<JugendDashboard> createState() => _JugendDashboardState();
}

class _JugendDashboardState extends ConsumerState<JugendDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    // Lade Gamification-Daten
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadGamificationData();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final gamificationData = ref.watch(gamificationProvider);

    // Verwende Gamification-Daten oder Fallback-Werte
    final totalCatches = gamificationData?.totalCatches ?? 0;
    final xpPoints = gamificationData?.xpPoints ?? 0;
    final level = gamificationData?.level ?? 1;
    final streak = gamificationData?.streak ?? 0;
    final rank = gamificationData?.rank ?? 0;
    final progress = gamificationData?.progressToNextLevel ?? 0.0;
    final xpInLevel = gamificationData?.xpInCurrentLevel ?? 0;
    final xpForNext = gamificationData?.xpForNextLevel ?? 200;
    final achievements = gamificationData?.achievements ?? [];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Custom App Bar mit Gradient
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: JugendGradients.primaryGradient,
                  ),
                  child: FlexibleSpaceBar(
                    title: const Text(
                      'ASV Jugend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: JugendGradients.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.waves,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (user != null) ...[
                    // Notification Bell mit Badge
                    _JugendNotificationBadge(),
                    IconButton(
                      tooltip: 'Abmelden',
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) context.go('/auth');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Card mit XP und Level
                          _buildWelcomeCard(level, xpPoints),
                          const SizedBox(height: 20),

                          // Stats Cards
                          _buildStatsRow(totalCatches, streak, rank),
                          const SizedBox(height: 20),

                          // Level Progress
                          _buildLevelProgress(level, progress, xpInLevel, xpForNext),
                          const SizedBox(height: 24),

                          // Action Buttons
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActionButtons(context),
                          const SizedBox(height: 24),

                          // Achievements
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAchievements(achievements),
                          const SizedBox(height: 24),

                          // Instagram Feed
                          const Text(
                            'Folge uns auf Instagram',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInstagramFeed(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(int level, int xpPoints) {
    return JugendCard(
      gradient: JugendGradients.purpleGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Willkommen zurück!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $level Angler',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$xpPoints XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gesamtpunkte',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalCatches, int streak, int rank) {
    return Row(
      children: [
        Expanded(
          child: JugendStatsBadge(
            label: 'Fänge',
            value: '$totalCatches',
            icon: Icons.phishing,
            gradient: JugendGradients.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: JugendStatsBadge(
            label: 'Streak',
            value: '$streak',
            icon: Icons.local_fire_department,
            gradient: JugendGradients.accentGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: JugendStatsBadge(
            label: 'Rang',
            value: rank > 0 ? '#$rank' : '-',
            icon: Icons.star,
            gradient: JugendGradients.successGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(int level, double progress, int xpInLevel, int xpForNext) {
    return JugendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nächstes Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: JugendGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level $level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JugendProgressBar(
            progress: progress,
            label: '$xpInLevel / $xpForNext XP',
            gradient: JugendGradients.primaryGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        JugendGradientButton(
          label: 'Fang erfassen',
          icon: Icons.add_circle_outline,
          gradient: JugendGradients.primaryGradient,
          onPressed: () => context.push('/catch/new'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: JugendGradientButton(
                label: 'Ranking',
                icon: Icons.leaderboard,
                gradient: JugendGradients.accentGradient,
                onPressed: () => context.push('/ranking'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: JugendGradientButton(
                label: 'Wetter',
                icon: Icons.wb_sunny,
                gradient: JugendGradients.successGradient,
                onPressed: () {
                  context.push('/weather');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        JugendGradientButton(
          label: 'Instagram Feed',
          icon: Icons.photo_camera,
          gradient: JugendGradients.purpleGradient,
          onPressed: () => context.push('/instagram'),
        ),
      ],
    );
  }

  Widget _buildAchievements(List achievements) {
    // Zeige nur die ersten 4 Achievements
    final displayAchievements = achievements.take(4).toList();

    // Gradients für Achievements
    final gradients = [
      JugendGradients.successGradient,
      JugendGradients.primaryGradient,
      JugendGradients.accentGradient,
      JugendGradients.purpleGradient,
    ];

    return JugendCard(
      child: Column(
        children: [
          if (displayAchievements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Noch keine Achievements freigeschaltet'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayAchievements.asMap().entries.map((entry) {
                final achievement = entry.value;
                final gradient = gradients[entry.key % gradients.length];

                // Icon mapping
                IconData icon;
                switch (achievement.iconName) {
                  case 'check_circle':
                    icon = Icons.check_circle;
                    break;
                  case 'emoji_events':
                    icon = Icons.emoji_events;
                    break;
                  case 'military_tech':
                    icon = Icons.military_tech;
                    break;
                  case 'workspace_premium':
                    icon = Icons.workspace_premium;
                    break;
                  case 'stars':
                    icon = Icons.stars;
                    break;
                  case 'local_fire_department':
                    icon = Icons.local_fire_department;
                    break;
                  default:
                    icon = Icons.emoji_events;
                }

                return JugendAchievementBadge(
                  title: achievement.title,
                  icon: icon,
                  unlocked: achievement.unlocked,
                  gradient: gradient,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInstagramFeed() {
    return JugendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: JugendGradients.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@asv_grossostheimjugend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ASV Großostheim Jugend',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse('https://www.instagram.com/asv_grossostheimjugend/');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: JugendGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Folgen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Instagram Feed Container
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('https://www.instagram.com/asv_grossostheimjugend/embed/'),
                ),
                initialSettings: InAppWebViewSettings(
                  transparentBackground: true,
                  supportZoom: false,
                  javaScriptEnabled: true,
                  disableHorizontalScroll: true,
                  disableVerticalScroll: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Neueste Posts von unserer Jugendabteilung',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification Badge Widget für Jugend Dashboard (mit weißem Icon)
class _JugendNotificationBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadNotificationsCountStreamProvider);

    return unreadCountAsync.when(
      data: (count) {
        return IconButton(
          tooltip: 'Benachrichtigungen',
          onPressed: () => context.push('/notifications'),
          icon: Badge(
            label: Text('$count'),
            isLabelVisible: count > 0,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            child: const Icon(Icons.notifications, color: Colors.white),
          ),
        );
      },
      loading: () => IconButton(
        tooltip: 'Benachrichtigungen',
        onPressed: () => context.push('/notifications'),
        icon: const Icon(Icons.notifications, color: Colors.white),
      ),
      error: (_, __) => IconButton(
        tooltip: 'Benachrichtigungen',
        onPressed: () => context.push('/notifications'),
        icon: const Icon(Icons.notifications, color: Colors.white),
      ),
    );
  }
}
