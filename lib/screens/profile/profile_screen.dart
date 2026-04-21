import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../models/quiz_result_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';

// ─── Tier helpers ────────────────────────────────────────────────────────────

typedef _TierInfo = ({String label, String emoji, int nextThreshold});

_TierInfo _tierInfo(int stars) {
  if (stars >= 60) return (label: 'Cyber Legend', emoji: '🏆', nextThreshold: 0);
  if (stars >= 30) return (label: 'Internet Guardian', emoji: '⚡', nextThreshold: 60);
  if (stars >= 15) return (label: 'Hero in Training', emoji: '🛡️', nextThreshold: 30);
  if (stars >= 5) return (label: 'Apprentice', emoji: '📱', nextThreshold: 15);
  return (label: 'Rookie', emoji: '🌱', nextThreshold: 5);
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(user: user)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatsRow(user: user)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 150))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 350)),
                const SizedBox(height: 20),
                _TierCard(stars: user.totalStars)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 250))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 350)),
                const SizedBox(height: 20),
                _RecentQuizzesSection(userId: user.id)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 350)),
                const SizedBox(height: 28),
                _SignOutButton(auth: auth)
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 450)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return Container(
      color: AppColors.teal,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 36),
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: const Duration(milliseconds: 700),
                ),
            const SizedBox(height: 12),
            Text(
              user.username,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Text(
                user.ageGroup.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          _StatCell(emoji: '⭐', value: '${user.totalStars}', label: 'Stars'),
          _vDivider(),
          _StatCell(
              emoji: '🎯',
              value: '${user.answeredQuestions.length}',
              label: 'Answered'),
          _vDivider(),
          _StatCell(
              emoji: '👥',
              value: '${user.friends.length}',
              label: 'Friends'),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: const Color(0xFFE5E7EB));
}

class _StatCell extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCell(
      {required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Tier card ───────────────────────────────────────────────────────────────

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.teal.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: AppColors.teal.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tier.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Rank',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
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
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMax
                ? '🎉 Maximum rank reached! You\'re a legend!'
                : '$starsToNext more ⭐ to reach $nextLabel',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Recent quizzes ──────────────────────────────────────────────────────────

class _RecentQuizzesSection extends StatelessWidget {
  final String userId;
  const _RecentQuizzesSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Quizzes',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<QuizResultModel>>(
          future: _fetchRecentResults(userId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.teal, strokeWidth: 2)),
              );
            }
            final results = snap.data ?? [];
            if (results.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Column(
                  children: [
                    Text('🎮', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 8),
                    Text('No quizzes yet',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Play your first quiz to see results here!',
                        style: TextStyle(
                            color: AppColors.textLight, fontSize: 12)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.topicName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                  '${result.categoryName} · ${_timeAgo(result.completedAt)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(
              3,
              (i) => Text(
                i < result.starsEarned ? '⭐' : '☆',
                style: const TextStyle(fontSize: 14),
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

// ─── Sign out button ─────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final AuthProvider auth;
  const _SignOutButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.wrong),
        label: const Text(
          'Sign Out',
          style: TextStyle(
              color: AppColors.wrong,
              fontWeight: FontWeight.bold,
              fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppColors.wrong.withOpacity(0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: AppColors.wrong))),
        ],
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
