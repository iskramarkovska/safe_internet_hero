import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/quiz_result_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';

// ─── Tier helpers ─────────────────────────────────────────────────────────────

typedef _TierInfo = ({
  String label,
  IconData icon,
  Color iconColor,
  int nextThreshold
});

_TierInfo _tierInfo(int stars) {
  if (stars >= 60) return (label: 'Cyber Legend', icon: Icons.emoji_events_rounded, iconColor: AppColors.gold, nextThreshold: 0);
  if (stars >= 30) return (label: 'Internet Guardian', icon: Icons.bolt_rounded, iconColor: AppColors.orange, nextThreshold: 60);
  if (stars >= 15) return (label: 'Hero in Training', icon: Icons.shield_rounded, iconColor: AppColors.blue, nextThreshold: 30);
  if (stars >= 5) return (label: 'Apprentice', icon: Icons.school_rounded, iconColor: AppColors.green, nextThreshold: 15);
  return (label: 'Rookie', icon: Icons.eco_rounded, iconColor: AppColors.greenDark, nextThreshold: 5);
}

int _tierFloor(int stars) {
  if (stars >= 60) return 60;
  if (stars >= 30) return 30;
  if (stars >= 15) return 15;
  if (stars >= 5) return 5;
  return 0;
}

Future<List<QuizResultModel>> _fetchRecentResults(String userId) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(5)
        .get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return QuizResultModel.fromMap(data);
    }).toList();
  } catch (_) {
    return [];
  }
}

// ─── Badge definitions ────────────────────────────────────────────────────────

const _badges = [
  (icon: Icons.lock_rounded, color: AppColors.categoryPrivacy, label: 'Privacy Pro', threshold: 1),
  (icon: Icons.vpn_key_rounded, color: AppColors.categoryPasswords, label: 'Key Master', threshold: 5),
  (icon: Icons.shield_rounded, color: AppColors.categoryCyberbullying, label: 'Defender', threshold: 10),
  (icon: Icons.smartphone_rounded, color: AppColors.categorySocialMedia, label: 'Social Safe', threshold: 20),
  (icon: Icons.phishing_rounded, color: AppColors.categoryPhishing, label: 'Phish Fighter', threshold: 30),
  (icon: Icons.emoji_events_rounded, color: AppColors.gold, label: 'Legend', threshold: 60),
];

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
          SliverToBoxAdapter(child: _ProfileHeader(user: user, showBackButton: showBackButton)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                _StatsRow(user: user)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 150))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 350)),

                const SizedBox(height: 16),

                // Tier card
                _TierCard(stars: user.totalStars)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 250))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 350)),

                const SizedBox(height: 20),

                // Badges
                _BadgesSection(stars: user.totalStars)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 350)),

                const SizedBox(height: 20),

                // Recent quizzes
                _RecentQuizzesSection(userId: user.id)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 450)),

                const SizedBox(height: 28),

                // Sign out
                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout_rounded,
                  onTap: () => _confirmSignOut(context, auth),
                ).animate().fadeIn(delay: const Duration(milliseconds: 550)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                    color: AppColors.redLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.red, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign Out?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
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
          context,
          AppPageRoute(builder: (_) => const AuthGate()),
          (r) => false,
        );
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
        child: Column(
          children: [
            // Back button row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Avatar
            AppAvatar(
              name: user.username,
              size: 96,
              borderColor: Colors.white,
              borderWidth: 4,
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 700),
                ),

            const SizedBox(height: 12),

            Text(
              user.username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 150)),

            const SizedBox(height: 6),

            // Tier badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tier.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    tier.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 220)),

            const SizedBox(height: 24),
          ],
        ),
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
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Create an account to track your progress',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
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
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.blueLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.blue, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create an account',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to track your progress,\nearn stars and climb the leaderboard!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
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
                          (r) => false,
                        );
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

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _StatCell(
              icon: Icons.star_rounded,
              iconColor: AppColors.gold,
              value: '${user.totalStars}',
              label: 'Stars'),
          _vDivider(),
          _StatCell(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.orange,
              value: '${user.currentStreak}',
              label: 'Streak'),
          _vDivider(),
          _StatCell(
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.orangeDark,
              value: '${user.coins}',
              label: 'Coins'),
          _vDivider(),
          _StatCell(
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.green,
              value: '${user.answeredQuestions.length}',
              label: 'Answered'),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 44, color: AppColors.border);
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCell(
      {required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Tier card ────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final int stars;
  const _TierCard({required this.stars});

  @override
  Widget build(BuildContext context) {
    final tier = _tierInfo(stars);
    final floor = _tierFloor(stars);
    final isMax = tier.nextThreshold == 0;
    final progress = isMax
        ? 1.0
        : (stars - floor) / (tier.nextThreshold - floor).toDouble();
    final starsToNext = isMax ? 0 : tier.nextThreshold - stars;
    final nextLabel = isMax ? '' : _tierInfo(tier.nextThreshold).label;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(tier.icon, color: tier.iconColor, size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rank',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    tier.label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMax
                ? 'Maximum rank reached — you\'re a legend!'
                : '$starsToNext more stars to reach $nextLabel',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Badges section ───────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final int stars;
  const _BadgesSection({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
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
                .animate(
                    delay: Duration(milliseconds: e.key * 80))
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 500),
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

  const _BadgeCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? AppColors.blueLight : AppColors.border,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              unlocked ? AppColors.blue.withValues(alpha: 0.3) : AppColors.borderDark,
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

// ─── Recent quizzes ───────────────────────────────────────────────────────────

class _RecentQuizzesSection extends StatefulWidget {
  final String userId;
  const _RecentQuizzesSection({required this.userId});

  @override
  State<_RecentQuizzesSection> createState() => _RecentQuizzesSectionState();
}

class _RecentQuizzesSectionState extends State<_RecentQuizzesSection> {
  Future<List<QuizResultModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchRecentResults(widget.userId);
  }

  @override
  void didUpdateWidget(_RecentQuizzesSection old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _future = _fetchRecentResults(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Quizzes',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<QuizResultModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(
                      color: AppColors.blue, strokeWidth: 2),
                ),
              );
            }
            final results = snap.data ?? [];
            if (results.isEmpty) {
              return AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.sports_esports_rounded,
                          color: AppColors.blue, size: 30),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No quizzes yet',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Play your first quiz to see results here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: results.asMap().entries.map((e) {
                return _QuizResultRow(result: e.value)
                    .animate(
                        delay: Duration(milliseconds: e.key * 60))
                    .fadeIn(duration: const Duration(milliseconds: 300))
                    .slideX(
                        begin: 0.05,
                        end: 0,
                        duration: const Duration(milliseconds: 300));
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _QuizResultRow extends StatelessWidget {
  final QuizResultModel result;
  const _QuizResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.quiz_rounded,
                  color: AppColors.blue, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.topicName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
                Text(
                  '${result.categoryName} · ${_timeAgo(result.completedAt)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(
              3,
              (i) => Icon(
                Icons.star_rounded,
                size: 16,
                color: i < result.starsEarned
                    ? AppColors.gold
                    : AppColors.borderDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}
