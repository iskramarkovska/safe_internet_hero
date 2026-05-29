import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';
import '../social/friends_screen.dart';

// ─── Tier helpers ─────────────────────────────────────────────────────────────

typedef _TierInfo = ({
  String label,
  IconData icon,
  Color iconColor,
  int nextThreshold
});

_TierInfo _tierInfo(int stars) {
  if (stars >= 60) return (label: 'Cyber Legend', icon: Icons.emoji_events_rounded, iconColor: AppColors.gold, nextThreshold: 0);
  if (stars >= 30) return (label: 'Guardian', icon: Icons.bolt_rounded, iconColor: AppColors.orange, nextThreshold: 60);
  if (stars >= 15) return (label: 'Hero', icon: Icons.shield_rounded, iconColor: AppColors.blue, nextThreshold: 30);
  if (stars >= 5) return (label: 'Apprentice', icon: Icons.school_rounded, iconColor: AppColors.green, nextThreshold: 15);
  return (label: 'Rookie', icon: Icons.eco_rounded, iconColor: AppColors.greenDark, nextThreshold: 5);
}

// ─── Badge / achievement definitions ─────────────────────────────────────────

const _badges = [
  (icon: Icons.lock_rounded, color: AppColors.categoryPrivacy, label: 'Privacy Pro', threshold: 1),
  (icon: Icons.vpn_key_rounded, color: AppColors.categoryPasswords, label: 'Key Master', threshold: 5),
  (icon: Icons.shield_rounded, color: AppColors.categoryCyberbullying, label: 'Defender', threshold: 10),
  (icon: Icons.smartphone_rounded, color: AppColors.categorySocialMedia, label: 'Social Safe', threshold: 20),
  (icon: Icons.phishing_rounded, color: AppColors.categoryPhishing, label: 'Phish Fighter', threshold: 30),
  (icon: Icons.emoji_events_rounded, color: AppColors.gold, label: 'Legend', threshold: 60),
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _joinedDate(DateTime d) {
  const m = ['January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'];
  return 'Joined ${m[d.month - 1]} ${d.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  final bool showBackButton;
  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (auth.isGuest || user == null) {
      return _GuestProfileScreen(showBackButton: showBackButton);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user, showBackButton: showBackButton),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistics grid
                _StatsGrid(user: user)
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideY(begin: 0.08, end: 0, duration: 350.ms),

                const SizedBox(height: 24),

                // Achievements / badges
                _AchievementsSection(stars: user.totalStars)
                    .animate()
                    .fadeIn(delay: 250.ms),

                const SizedBox(height: 24),

                // Friends
                _FriendsSection(user: user, auth: auth)
                    .animate()
                    .fadeIn(delay: 350.ms),

                const SizedBox(height: 28),

                // Sign out
                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout_rounded,
                  onTap: () => _confirmSignOut(context, auth),
                ).animate().fadeIn(delay: 450.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.redLight, shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.red, size: 28),
                ),
                const SizedBox(height: 12),
                const Text('Sign Out?',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Are you sure you want to sign out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.secondary,
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Sign Out',
                        variant: AppButtonVariant.danger,
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context, AppPageRoute(builder: (_) => const AuthGate()), (r) => false);
      }
    }
  }
}

// ─── Profile header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool showBackButton;
  const _ProfileHeader({required this.user, required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    final tier = _tierInfo(user.totalStars);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue, Color(0xFF5AB4F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top action row
              Row(
                children: [
                  if (showBackButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const Expanded(
                    child: Text('My Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                  ),
                  // Edit icon (placeholder for future avatar change)
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Character card + info row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Character avatar card
                  _CharacterCard(username: user.username)
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                        duration: 700.ms,
                      ),

                  const SizedBox(width: 20),

                  // Info column
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ).animate().fadeIn(delay: 150.ms),

                          const SizedBox(height: 6),

                          // Tier badge pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tier.icon,
                                    color: Colors.white, size: 13),
                                const SizedBox(width: 5),
                                Text(tier.label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 8),

                          Text(
                            _joinedDate(user.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(delay: 250.ms),

                          const SizedBox(height: 4),

                          Text(
                            '${user.friends.length} ${user.friends.length == 1 ? 'Friend' : 'Friends'}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Character avatar card ────────────────────────────────────────────────────

class _CharacterCard extends StatelessWidget {
  final String username;
  const _CharacterCard({required this.username});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 140,
      child: Stack(
        children: [
          // Card background
          Container(
            width: 130,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45), width: 2),
            ),
            child: Center(
              child: AppAvatar(name: username, size: 80),
            ),
          ),
          // Add / change avatar button
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.blue, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest profile screen ─────────────────────────────────────────────────────

class _GuestProfileScreen extends StatelessWidget {
  final bool showBackButton;
  const _GuestProfileScreen({required this.showBackButton});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const AppTopBar(stars: 0, streak: 0, coins: 0),
                Container(height: 1, color: AppColors.border),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.blue, Color(0xFF5AB4F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profile',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Create an account to track your progress',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(
                          color: AppColors.blueLight, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.blue, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text('Create an account',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to track your progress,\nearn stars and climb the leaderboard!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Get Started — It\'s Free!',
                      variant: AppButtonVariant.success,
                      icon: Icons.person_add_rounded,
                      onTap: () {
                        context.read<AuthProvider>().exitGuestMode();
                        Navigator.pushAndRemoveUntil(
                            context,
                            AppPageRoute(builder: (_) => const AuthGate()),
                            (r) => false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Statistics grid ──────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final UserModel user;
  const _StatsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final tier = _tierInfo(user.totalStars);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics',
            style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.orange,
                value: '${user.currentStreak}',
                label: 'Day streak',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                iconColor: AppColors.gold,
                value: '${user.totalStars}',
                label: 'Total XP',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: tier.icon,
                iconColor: tier.iconColor,
                value: tier.label,
                label: 'League',
                smallValue: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.green,
                value: '${user.answeredQuestions.length}',
                label: 'Quizzes done',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: smallValue ? 13 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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

// ─── Achievements section ─────────────────────────────────────────────────────

class _AchievementsSection extends StatelessWidget {
  final int stars;
  const _AchievementsSection({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Achievements',
            style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: _badges.asMap().entries.map((e) {
            final badge = e.value;
            final unlocked = stars >= badge.threshold;
            return _BadgeCell(
              icon: badge.icon,
              color: badge.color,
              label: badge.label,
              unlocked: unlocked,
            )
                .animate(delay: Duration(milliseconds: e.key * 80))
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 500.ms,
                );
          }).toList(),
        ),
      ],
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool unlocked;
  const _BadgeCell(
      {required this.icon,
      required this.color,
      required this.label,
      required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? AppColors.blueLight : AppColors.border,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppColors.blue.withValues(alpha: 0.3)
              : AppColors.borderDark,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          unlocked
              ? Icon(icon, color: color, size: 32)
              : const Icon(Icons.lock_rounded,
                  color: AppColors.textLight, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked ? AppColors.blue : AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Friends section ──────────────────────────────────────────────────────────

class _FriendsSection extends StatefulWidget {
  final UserModel user;
  final AuthProvider auth;
  const _FriendsSection({required this.user, required this.auth});

  @override
  State<_FriendsSection> createState() => _FriendsSectionState();
}

class _FriendsSectionState extends State<_FriendsSection> {
  final _friendService = FriendService();
  List<UserModel> _friends = [];
  List<UserModel> _requesters = [];
  bool _loading = true;
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.user.id);
  }

  @override
  void didUpdateWidget(_FriendsSection old) {
    super.didUpdateWidget(old);
    if (old.user.id != widget.user.id) {
      _sub?.cancel();
      _subscribe(widget.user.id);
    }
  }

  void _subscribe(String userId) {
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(_onSnapshot);
  }

  void _onSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    _loadFriends(List<String>.from(data['friends'] ?? []));
    _loadRequesters(List<String>.from(data['friendRequests'] ?? []));
  }

  Future<void> _loadFriends(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() { _friends = []; _loading = false; });
      return;
    }
    final users = await _friendService.getUsersByIds(ids);
    if (!mounted) return;
    setState(() { _friends = users; _loading = false; });
  }

  Future<void> _loadRequesters(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() => _requesters = []);
      return;
    }
    final users = await _friendService.getUsersByIds(ids);
    if (!mounted) return;
    setState(() => _requesters = users);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _openAddFriends() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFriendsSheet(
        currentUser: widget.user,
        friendService: _friendService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _loading || _friends.isEmpty
                  ? 'Friends'
                  : 'Friends (${_friends.length})',
              style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900),
            ),
            GestureDetector(
              onTap: _openAddFriends,
              child: const Text(
                'ADD FRIENDS',
                style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                  color: AppColors.blue, strokeWidth: 2),
            ),
          )
        else if (_friends.isEmpty)
          _buildEmptyState()
        else
          _buildFriendsList(),
      ],
    );
  }

  static const _previewCount = 3;

  Widget _buildFriendsList() {
    final preview = _friends.take(_previewCount).toList();
    final hasMore = _friends.length > _previewCount;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ...preview.asMap().entries.map((e) {
              final friend = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AppAvatar(name: friend.username, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend.username,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text('${friend.totalStars} XP',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 15),
                            const SizedBox(width: 3),
                            Text('${friend.totalStars}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                      height: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 16)),
                ],
              );
            }),

            // "View all" row — opens on FOLLOWERS tab if requests are pending
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                AppPageRoute(
                  builder: (_) => AllFriendsScreen(
                    user: widget.user,
                    initialTab: _requesters.isNotEmpty ? 1 : 0,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      hasMore
                          ? 'View all (${_friends.length})'
                          : 'View all',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                    if (_requesters.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_requesters.length} request${_requesters.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.people_outline_rounded,
                color: AppColors.blue, size: 30),
          ),
          const SizedBox(height: 8),
          const Text('No friends yet',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Add friends to compete and see their progress!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add Friends',
            variant: AppButtonVariant.primary,
            icon: Icons.person_add_rounded,
            onTap: _openAddFriends,
          ),
        ],
      ),
    );
  }
}

// ─── Add Friends bottom sheet ─────────────────────────────────────────────────

class _AddFriendsSheet extends StatefulWidget {
  final UserModel currentUser;
  final FriendService friendService;
  const _AddFriendsSheet(
      {required this.currentUser, required this.friendService});

  @override
  State<_AddFriendsSheet> createState() => _AddFriendsSheetState();
}

class _AddFriendsSheetState extends State<_AddFriendsSheet> {
  static const _pageSize = 10;

  final _controller = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;
  Timer? _debounce;
  int _visibleCount = _pageSize;

  // Optimistic local overrides — no list reload on tap.
  final Set<String> _pendingRequests = {};
  final Set<String> _cancelledRequests = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _loading = false; _visibleCount = _pageSize; });
      return;
    }
    setState(() { _loading = true; _visibleCount = _pageSize; });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      try {
        final results = await widget.friendService.searchUsers(query);
        if (!mounted) return;
        setState(() { _results = results; _loading = false; });
      } catch (e) {
        if (!mounted) return;
        setState(() { _results = []; _loading = false; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _results.where((r) => r.id != widget.currentUser.id).toList();
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > _visibleCount;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'Search for friends',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _search,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 15),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFAAAAAA), size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            _search('');
                          },
                          child: const Icon(Icons.cancel_rounded,
                              color: Color(0xFFAAAAAA), size: 20),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 13),
                ),
              ),
            ),
          ),

          // Divider under search bar
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          ),

          // Result count
          if (!_loading && _controller.text.isNotEmpty && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Body
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.blue, strokeWidth: 2))
                : _controller.text.isEmpty
                    ? _buildPrompt()
                    : filtered.isEmpty
                        ? _buildNoResults()
                        : _buildList(visible, hasMore, filtered.length),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_search_rounded,
                size: 52, color: Color(0xFFCCCCCC)),
            SizedBox(height: 14),
            Text('Find people you know',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Type a username to search',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Color(0xFFCCCCCC), size: 48),
            const SizedBox(height: 14),
            Text('No results for "${_controller.text}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Try a different username',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<UserModel> visible, bool hasMore, int total) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Column(
          children: [
            // Result rows
            ...List.generate(visible.length, (index) {
              final result = visible[index];
              final isFriend = widget.currentUser.friends.contains(result.id);
              final isRequested = !_cancelledRequests.contains(result.id) &&
                  (_pendingRequests.contains(result.id) ||
                      result.friendRequests.contains(widget.currentUser.id));
              final isLast = index == visible.length - 1 && !hasMore;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        AppAvatar(name: result.username, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.username,
                                  style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('@${result.username}',
                                  style: const TextStyle(
                                      color: Color(0xFFAAAAAA),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isFriend)
                          _ActionChip(
                            icon: Icons.check_rounded,
                            label: 'Friends',
                            bg: const Color(0xFFE8F5E9),
                            fg: const Color(0xFF388E3C),
                            onTap: null,
                          )
                        else if (isRequested)
                          _ActionChip(
                            icon: Icons.person_remove_outlined,
                            label: 'Requested',
                            bg: const Color(0xFFE3F2FD),
                            fg: AppColors.blue,
                            onTap: () async {
                              setState(() {
                                _cancelledRequests.add(result.id);
                                _pendingRequests.remove(result.id);
                              });
                              await widget.friendService.cancelFriendRequest(
                                  widget.currentUser.id, result.id);
                            },
                          )
                        else
                          _ActionChip(
                            icon: Icons.person_add_outlined,
                            label: 'Add',
                            bg: AppColors.blue,
                            fg: Colors.white,
                            onTap: () async {
                              setState(() {
                                _pendingRequests.add(result.id);
                                _cancelledRequests.remove(result.id);
                              });
                              await widget.friendService.sendFriendRequest(
                                  widget.currentUser.id, result.id);
                            },
                          ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 70,
                        color: Color(0xFFF0F0F0)),
                ],
              );
            }),

            // Load more row
            if (hasMore)
              GestureDetector(
                onTap: () => setState(
                    () => _visibleCount = _visibleCount + _pageSize),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Color(0xFFE8E8E8), width: 1)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Load more',
                          style: TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF555555), size: 18),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 15),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
