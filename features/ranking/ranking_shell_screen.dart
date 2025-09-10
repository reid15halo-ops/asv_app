import 'package:flutter/material.dart';
import '../gamification/leaderboard_screen.dart';
import 'trophy_board_screen.dart';

class RankingShellScreen extends StatefulWidget {
  const RankingShellScreen({super.key});
  @override
  State<RankingShellScreen> createState() => _RankingShellState();
}

class _RankingShellState extends State<RankingShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        bottom: TabBar(
          controller: _tc,
          tabs: const [Tab(text: 'Trophäen'), Tab(text: 'XP')],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [TrophyBoardScreen(), LeaderboardScreen()],
      ),
    );
  }
}
