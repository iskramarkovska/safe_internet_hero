import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_avatar.dart';
import 'home_screen.dart';
import '../learn/learn_screen.dart';
import '../shop/shop_screen.dart';
import '../social/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const _screens = [
    HomeScreen(),
    LearnScreen(),
    ShopScreen(),
    LeaderboardScreen(),
    ProfileScreen(showBackButton: false),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

    if (desktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Row(
              children: [
                _DesktopRail(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                ),
                Container(width: 1, color: AppColors.border),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
            Positioned(
              top: kDesktopPanelMargin,
              right: kDesktopPanelMargin,
              bottom: kDesktopPanelMargin,
              child: SizedBox(
                width: kDesktopPanelWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.09),
                        blurRadius: 28,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const _DesktopSidePanel(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _DuolingoBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Desktop navigation rail ──────────────────────────────────────────────────

class _DesktopRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _DesktopRail({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.menu_book_rounded, label: 'Learn'),
    (icon: Icons.storefront_rounded, label: 'Shop'),
    (icon: Icons.leaderboard_rounded, label: 'Leaderboard'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 216,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/mascot.svg',
                      width: 34,
                      height: 34,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Safe Internet\nHero',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              ...List.generate(_items.length, (i) => _RailItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.blueLight
                : _hovered
                    ? AppColors.background
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: widget.selected
                ? Border.all(
                    color: AppColors.blue.withValues(alpha: 0.25), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.selected
                    ? AppColors.blue
                    : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  color: widget.selected
                      ? AppColors.blue
                      : AppColors.textSecondary,
                  fontWeight: widget.selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile bottom navigation ─────────────────────────────────────────────────

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
    'assets/images/store.svg',
    'assets/images/leaderboard.svg',
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
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(color: AppColors.blue, width: 2)
                              : null,
                        ),
                        child: SvgPicture.asset(
                          _svgPaths[i],
                          width: 30,
                          height: 30,
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

// ─── Desktop side panel ───────────────────────────────────────────────────────

class _DesktopSidePanel extends StatelessWidget {
  const _DesktopSidePanel();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final username = isGuest ? 'Hero' : (user?.username ?? 'Hero');
    final stars = user?.totalStars ?? 0;
    final streak = user?.currentStreak ?? 0;
    final coins = user?.coins ?? 0;
    final hasGoldFrame = user?.hasGoldFrame ?? false;
    final xpBoostActive = user?.xpBoostActive ?? false;
    final freezeCount = user?.streakFreezeCount ?? 0;
    final ageGroup = user?.ageGroup;

    return Container(
      color: Colors.white,
      child: SafeArea(
        left: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile ──────────────────────────────────────────────
              Row(
                children: [
                  AppAvatar(
                    name: username,
                    size: 52,
                    goldFrame: hasGoldFrame,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (ageGroup != null) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blueLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ageGroup.name[0].toUpperCase() +
                                  ageGroup.name.substring(1),
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // ── Stats label ───────────────────────────────────────────
              Text(
                'YOUR STATS',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              _StatCard(
                icon: Icons.local_fire_department_rounded,
                color: streak > 0 ? AppColors.orange : AppColors.textLight,
                label: 'Day Streak',
                value: '$streak',
              ),
              const SizedBox(height: 10),
              _StatCard(
                icon: Icons.star_rounded,
                color: AppColors.gold,
                label: 'Total Stars',
                value: '$stars',
              ),
              const SizedBox(height: 10),
              _StatCard(
                icon: Icons.monetization_on_rounded,
                color: AppColors.orangeDark,
                label: 'Coins',
                value: '$coins',
              ),

              // ── Active boosts ─────────────────────────────────────────
              if (xpBoostActive || freezeCount > 0) ...[
                const SizedBox(height: 20),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 20),
                Text(
                  'ACTIVE BOOSTS',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLight,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                if (xpBoostActive) ...[
                  const _BoostBanner(),
                  if (freezeCount > 0) const SizedBox(height: 10),
                ],
                if (freezeCount > 0) _FreezeBanner(count: freezeCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Boost banners ────────────────────────────────────────────────────────────

class _BoostBanner extends StatelessWidget {
  const _BoostBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.15),
            AppColors.orange.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XP Boost Active',
                  style: GoogleFonts.nunito(
                    color: AppColors.orangeDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '2× stars on quizzes',
                  style: GoogleFonts.nunito(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreezeBanner extends StatelessWidget {
  final int count;
  const _FreezeBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.ac_unit_rounded,
                color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Streak Freeze${count > 1 ? 's' : ''}',
                  style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Your streak is protected',
                  style: GoogleFonts.nunito(
                    color: AppColors.blueDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
