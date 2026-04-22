import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/topic_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/splash_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/topics_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _tierLabel(int stars) {
  if (stars >= 60) return 'Cyber Legend';
  if (stars >= 30) return 'Internet Guardian';
  if (stars >= 15) return 'Hero in Training';
  if (stars >= 5) return 'Apprentice';
  return 'Rookie';
}

IconData _tierIcon(int stars) {
  if (stars >= 60) return Icons.emoji_events_rounded;
  if (stars >= 30) return Icons.bolt_rounded;
  if (stars >= 15) return Icons.shield_rounded;
  if (stars >= 5) return Icons.school_rounded;
  return Icons.eco_rounded;
}

Color _tierIconColor(int stars) {
  if (stars >= 60) return AppColors.gold;
  if (stars >= 30) return AppColors.orange;
  if (stars >= 15) return AppColors.blue;
  if (stars >= 5) return AppColors.green;
  return AppColors.greenDark;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicsService = TopicsService();
  final _questionService = QuestionService();

  Future<int> _completedTopics(
      UserModel user, String categoryId, List<TopicModel> topics) async {
    int count = 0;
    for (final t in topics) {
      final total = await _questionService.getTotalQuestionsCount(
          categoryId: categoryId, topicId: t.id);
      if (total == 0) continue;
      final all = await _questionService.getQuestions(
          categoryId: categoryId, topicId: t.id, limit: 1000);
      final answered =
          all.where((q) => user.answeredQuestions.contains(q.id)).length;
      if (answered >= total) count++;
    }
    return count;
  }

  Future<void> _confirmLogout(BuildContext context) async {
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
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.blue, size: 28),
                ),
                const SizedBox(height: 12),
                Text('Sign out?',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Nunito')),
                const SizedBox(height: 8),
                Text('Are you sure you want to leave?',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final username = isGuest ? 'Guest' : (user?.username ?? 'Hero');
    final stars = user?.totalStars ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Status bar + top bar ──────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  stars: stars,
                  streak: 1,
                  username: isGuest ? null : username,
                  onAvatarTap: isGuest
                      ? null
                      : () => Navigator.push(context,
                          AppPageRoute(builder: (_) => const ProfileScreen())),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Inline greeting ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey, $username!',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(_tierIcon(stars),
                                    color: _tierIconColor(stars), size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  _tierLabel(stars),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.textLight, size: 20),
                        onPressed: () => _confirmLogout(context),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 400))
                      .slideY(
                          begin: 0.06,
                          end: 0,
                          duration: const Duration(milliseconds: 350)),

                  const SizedBox(height: 20),

                  // ── Section header ────────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Keep Learning',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                              AppPageRoute(builder: (_) => const TopicsScreen())),
                          child: const Text(
                            'See all',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: const Duration(milliseconds: 100))
                      .fadeIn(duration: const Duration(milliseconds: 300)),

                  const SizedBox(height: 12),

                  // ── Category cards ────────────────────────────────────────
                  StreamBuilder<List<CategoryModel>>(
                    stream: _topicsService.watchCategories(),
                    builder: (context, catSnap) {
                      if (!catSnap.hasData) {
                        return Column(
                          children: List.generate(
                              3, (_) => const _CategoryCardSkeleton()),
                        );
                      }

                      return StreamBuilder<List<TopicModel>>(
                        stream: _topicsService.watchAllTopics(),
                        builder: (context, topicSnap) {
                          if (!topicSnap.hasData) {
                            return Column(
                              children: List.generate(
                                  3, (_) => const _CategoryCardSkeleton()),
                            );
                          }

                          final categories = catSnap.data!;
                          final allTopics = topicSnap.data!;

                          return Column(
                            children: categories.asMap().entries.map((e) {
                              final cat = e.value;
                              final topics = allTopics
                                  .where((t) => t.categoryId == cat.id)
                                  .toList()
                                ..sort((a, b) => a.order.compareTo(b.order));

                              return _CategoryCard(
                                category: cat,
                                topics: topics,
                                user: user,
                                isGuest: isGuest,
                                completedTopics: _completedTopics,
                                onTap: () => Navigator.push(
                                    context,
                                    AppPageRoute(
                                        builder: (_) => TopicsScreen(
                                              filterCategoryId: cat.id,
                                              filterCategoryTitle: cat.title,
                                            ))),
                              )
                                  .animate(
                                      delay: Duration(
                                          milliseconds:
                                              200 + e.key * 100))
                                  .fadeIn(
                                      duration:
                                          const Duration(milliseconds: 350))
                                  .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration:
                                          const Duration(milliseconds: 350),
                                      curve: Curves.easeOut);
                            }).toList(),
                          );
                        },
                      );
                    },
                  ),

                  // ── Admin panel ───────────────────────────────────────────
                  if (user?.isAdmin == true) ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Admin Panel',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.admin_panel_settings_rounded,
                      onTap: () => Navigator.push(context,
                          AppPageRoute(builder: (_) => const AdminDashboardScreen())),
                    ).animate(delay: const Duration(milliseconds: 500)).fadeIn(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final UserModel? user;
  final bool isGuest;
  final Future<int> Function(UserModel, String, List<TopicModel>)
      completedTopics;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.topics,
    required this.user,
    required this.isGuest,
    required this.completedTopics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppCategoryIcon.colorFor(category.title);
    final total = topics.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.blueLight,
          highlightColor: AppColors.blueLight.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(AppCategoryIcon.iconFor(category.title),
                      color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (!isGuest && user != null)
                        FutureBuilder<int>(
                          future: completedTopics(user!, category.id, topics),
                          builder: (ctx, snap) {
                            final done = snap.data ?? 0;
                            final progress = total == 0 ? 0.0 : done / total;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: progress),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOut,
                                    builder: (_, v, __) =>
                                        LinearProgressIndicator(
                                      value: v,
                                      minHeight: 8,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.blue),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$done / $total topics',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      else
                        Text(
                          '$total topics',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.borderDark, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1000));
  }
}
