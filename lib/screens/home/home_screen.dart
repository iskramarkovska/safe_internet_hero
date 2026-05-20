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

String _timeGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

IconData _timeIcon() {
  final hour = DateTime.now().hour;
  if (hour < 12) return Icons.wb_sunny_rounded;
  if (hour < 17) return Icons.light_mode_rounded;
  return Icons.nights_stay_rounded;
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
    if (topics.isEmpty) return 0;
    final results = await Future.wait(
      topics.map((t) async {
        final total = await _questionService.getTotalQuestionsCount(
            categoryId: categoryId, topicId: t.id);
        if (total == 0) return false;
        final all = await _questionService.getQuestions(
            categoryId: categoryId, topicId: t.id, limit: 1000);
        final answered =
            all.where((q) => user.answeredQuestions.contains(q.id)).length;
        return answered >= total;
      }),
    );
    return results.where((done) => done).length;
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
                  width: 56,
                  height: 56,
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
          // ── Top bar ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  stars: stars,
                  streak: 0,
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

                  // ── Greeting ──────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_timeIcon(),
                                    color: AppColors.blue, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  _timeGreeting().toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              username,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
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

                  // ── Categories (featured + cards) ─────────────────────────
                  StreamBuilder<List<CategoryModel>>(
                    stream: _topicsService.watchCategories(),
                    builder: (context, catSnap) {
                      if (catSnap.hasError) return _buildStreamError();
                      if (!catSnap.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FeaturedCardSkeleton(),
                            const SizedBox(height: 20),
                            _sectionHeader(context),
                            const SizedBox(height: 12),
                            ...List.generate(
                                3, (_) => const _QuizCardSkeleton()),
                          ],
                        );
                      }

                      return StreamBuilder<List<TopicModel>>(
                        stream: _topicsService.watchAllTopics(),
                        builder: (context, topicSnap) {
                          if (topicSnap.hasError) return _buildStreamError();
                          if (!topicSnap.hasData) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FeaturedCardSkeleton(),
                                const SizedBox(height: 20),
                                _sectionHeader(context),
                                const SizedBox(height: 12),
                                ...List.generate(
                                    3, (_) => const _QuizCardSkeleton()),
                              ],
                            );
                          }

                          final categories = catSnap.data!;
                          final allTopics = topicSnap.data!;

                          List<TopicModel> topicsFor(String catId) => allTopics
                              .where((t) => t.categoryId == catId)
                              .toList()
                            ..sort((a, b) => a.order.compareTo(b.order));

                          final featured =
                              categories.isNotEmpty ? categories.first : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Featured card ─────────────────────────────
                              if (featured != null)
                                _FeaturedCard(
                                  category: featured,
                                  topicCount: topicsFor(featured.id).length,
                                  onTap: () => Navigator.push(
                                      context,
                                      AppPageRoute(
                                          builder: (_) => TopicsScreen(
                                                filterCategoryId: featured.id,
                                                filterCategoryTitle:
                                                    featured.title,
                                              ))),
                                )
                                    .animate(
                                        delay: const Duration(
                                            milliseconds: 100))
                                    .fadeIn(
                                        duration:
                                            const Duration(milliseconds: 400))
                                    .slideY(
                                        begin: 0.08,
                                        end: 0,
                                        duration:
                                            const Duration(milliseconds: 400),
                                        curve: Curves.easeOut),

                              const SizedBox(height: 20),

                              // ── Section header ────────────────────────────
                              _sectionHeader(context)
                                  .animate(
                                      delay:
                                          const Duration(milliseconds: 200))
                                  .fadeIn(
                                      duration:
                                          const Duration(milliseconds: 300)),

                              const SizedBox(height: 12),

                              // ── Quiz cards ────────────────────────────────
                              ...categories.asMap().entries.map((e) {
                                final cat = e.value;
                                final topics = topicsFor(cat.id);
                                return _QuizCard(
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
                                                250 + e.key * 80))
                                    .fadeIn(
                                        duration:
                                            const Duration(milliseconds: 320))
                                    .slideY(
                                        begin: 0.08,
                                        end: 0,
                                        duration:
                                            const Duration(milliseconds: 320),
                                        curve: Curves.easeOut);
                              }),
                            ],
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
                      onTap: () => Navigator.push(
                          context,
                          AppPageRoute(
                              builder: (_) =>
                                  const AdminDashboardScreen())),
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

  Widget _buildStreamError() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textLight, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not load content',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _sectionHeader(BuildContext context) => Row(
        children: [
          const Text(
            'Your Quizzes',
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
              onTap: () => Navigator.push(
                  context, AppPageRoute(builder: (_) => const TopicsScreen())),
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
      );
}

// ─── Featured card ─────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final CategoryModel category;
  final int topicCount;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.category,
    required this.topicCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppCategoryIcon.colorFor(category.title);
    final darkColor = AppCategoryIcon.darkColorFor(category.title);
    final icon = AppCategoryIcon.iconFor(category.title);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                color,
                darkColor,
                const Color(0xFF1A1A2E),
              ],
              stops: const [0.0, 0.45, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                category.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '$topicCount topics',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Label
                    Text(
                      'Featured',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      'Start Learning\n${category.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Start Now',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.arrow_forward_rounded,
                                color: color, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quiz card ─────────────────────────────────────────────────────────────────

class _QuizCard extends StatefulWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final UserModel? user;
  final bool isGuest;
  final Future<int> Function(UserModel, String, List<TopicModel>)
      completedTopics;
  final VoidCallback onTap;

  const _QuizCard({
    required this.category,
    required this.topics,
    required this.user,
    required this.isGuest,
    required this.completedTopics,
    required this.onTap,
  });

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  Future<int>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(_QuizCard old) {
    super.didUpdateWidget(old);
    // Re-fetch only when the identity-relevant fields change.
    if (old.user?.id != widget.user?.id ||
        old.category.id != widget.category.id ||
        old.topics.length != widget.topics.length) {
      _initFuture();
    }
  }

  void _initFuture() {
    if (!widget.isGuest && widget.user != null) {
      _progressFuture = widget.completedTopics(
          widget.user!, widget.category.id, widget.topics);
    } else {
      _progressFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppCategoryIcon.colorFor(widget.category.title);
    final total = widget.topics.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                AppCategoryIcon(title: widget.category.title, size: 52),
                const SizedBox(width: 12),

                // Name + count + progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$total Topics',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!widget.isGuest && widget.user != null &&
                          _progressFuture != null) ...[
                        const SizedBox(height: 7),
                        FutureBuilder<int>(
                          future: _progressFuture,
                          builder: (ctx, snap) {
                            final done = snap.data ?? 0;
                            final progress =
                                total == 0 ? 0.0 : done / total;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration:
                                    const Duration(milliseconds: 900),
                                curve: Curves.easeOut,
                                builder: (_, v, __) =>
                                    LinearProgressIndicator(
                                  value: v,
                                  minHeight: 5,
                                  backgroundColor: AppColors.border,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          iconColor),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Start button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: iconColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Start',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _FeaturedCardSkeleton extends StatelessWidget {
  const _FeaturedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(24),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1000));
  }
}

class _QuizCardSkeleton extends StatelessWidget {
  const _QuizCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(18),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1000));
  }
}
