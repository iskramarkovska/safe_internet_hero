import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'topics_screen.dart';
import 'leaderboard_screen.dart';
import 'activity_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TopicsScreen(),
    const LeaderboardScreen(),
    const ActivityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                label: 'Topics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard_rounded),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bolt_rounded),
                label: 'Activity',
              ),
            ],
          ),
        ),
      ),
    );
  }
}