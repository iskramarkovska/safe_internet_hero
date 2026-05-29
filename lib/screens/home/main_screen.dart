import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import '../learn/learn_screen.dart';
import '../social/leaderboard_screen.dart';
import '../social/activity_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    LeaderboardScreen(),
    ActivityScreen(),
    ProfileScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _DuolingoBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _DuolingoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DuolingoBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _svgPaths = [
    'assets/images/home.svg',
    'assets/images/learn.svg',
    'assets/images/leaderboard.svg',
    'assets/images/activity.svg',
    'assets/images/profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(_svgPaths.length, (i) {
              final selected = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(color: AppColors.blue, width: 2)
                              : null,
                        ),
                        child: SvgPicture.asset(
                          _svgPaths[i],
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
