import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../quiz/quiz_screen.dart';
import '../quiz/topics_screen.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicsService = TopicsService();
  final _questionService = QuestionService();

  Future<int> _completedTopicCount(
      UserModel user, String categoryId, List<TopicModel> topics) async {
    if (topics.isEmpty) return 0;
    final results = await Future.wait(topics.map((t) async {
      final total = await _questionService.getTotalQuestionsCount(
          categoryId: categoryId, topicId: t.id);
      if (total == 0) return false;
      final all = await _questionService.getQuestions(
          categoryId: categoryId, topicId: t.id, limit: 1000);
      return all.where((q) => user.answeredQuestions.contains(q.id)).length >=
          total;
    }));
    return results.where((done) => done).length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;
    final username = isGuest ? 'Hero' : (user?.username ?? 'Hero');
    final stars = user?.totalStars ?? 0;
    final streak = user?.currentStreak ?? 0;
    final coins = user?.coins ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top stats bar ──────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  stars: stars,
                  streak: streak,
                  coins: coins,
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Scrollable body ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero banner ────────────────────────────────────────────
                  _HeroBanner(username: username)
                      .animate()
                      .fadeIn(duration: 400.ms),

                  // ── Padded content ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Practice weak spots
                        if (!isGuest &&
                            user != null &&
                            user.incorrectlyAnsweredIds.length >= 3) ...[
                          _PracticeCard(
                            count: user.incorrectlyAnsweredIds.length,
                            onTap: () => Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) => QuizScreen(
                                  categoryId: 'practice',
                                  categoryName: 'Practice',
                                  topicId: '',
                                  topicName: 'Weak Spots',
                                  color: AppColors.orange,
                                  specificIds: user.incorrectlyAnsweredIds
                                      .take(10)
                                      .toList(),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.06, end: 0, duration: 350.ms),
                          const SizedBox(height: 24),
                        ],

                        // Section header
                        _SectionHeader(
                          onSeeAll: () => Navigator.push(
                            context,
                            AppPageRoute(
                                builder: (_) => const TopicsScreen()),
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 300.ms),

                        const SizedBox(height: 14),

                        // Category quest cards
                        StreamBuilder<List<CategoryModel>>(
                          stream: _topicsService.watchCategories(),
                          builder: (context, catSnap) {
                            if (catSnap.hasError) return _buildError();
                            return StreamBuilder<List<TopicModel>>(
                              stream: _topicsService.watchAllTopics(),
                              builder: (context, topicSnap) {
                                if (topicSnap.hasError) return _buildError();

                                if (!catSnap.hasData || !topicSnap.hasData) {
                                  return Column(
                                    children: List.generate(
                                        3, (_) => const _QuestCardSkeleton()),
                                  );
                                }

                                final categories = catSnap.data!;
                                final allTopics = topicSnap.data!;

                                List<TopicModel> topicsFor(String catId) =>
                                    allTopics
                                        .where((t) => t.categoryId == catId)
                                        .toList()
                                      ..sort(
                                          (a, b) => a.order.compareTo(b.order));

                                return Column(
                                  children: categories.asMap().entries.map((e) {
                                    final cat = e.value;
                                    final topics = topicsFor(cat.id);
                                    return _QuestCard(
                                      category: cat,
                                      topics: topics,
                                      user: user,
                                      isGuest: isGuest,
                                      completedTopics: _completedTopicCount,
                                      onTap: () => Navigator.push(
                                        context,
                                        AppPageRoute(
                                          builder: (_) => TopicsScreen(
                                            filterCategoryId: cat.id,
                                            filterCategoryTitle: cat.title,
                                          ),
                                        ),
                                      ),
                                    )
                                        .animate(
                                            delay: Duration(
                                                milliseconds:
                                                    150 + e.key * 70))
                                        .fadeIn(duration: 300.ms)
                                        .slideY(
                                            begin: 0.07,
                                            end: 0,
                                            duration: 300.ms,
                                            curve: Curves.easeOut);
                                  }).toList(),
                                );
                              },
                            );
                          },
                        ),

                        // Admin button
                        if (user?.isAdmin == true) ...[
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Admin Panel',
                            variant: AppButtonVariant.secondary,
                            icon: Icons.admin_panel_settings_rounded,
                            onTap: () => Navigator.push(
                                context,
                                AppPageRoute(
                                    builder: (_) =>
                                        const AdminDashboardScreen())),
                          ).animate(delay: 500.ms).fadeIn(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textLight, size: 36),
              const SizedBox(height: 10),
              const Text('Could not load content',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
              TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry')),
            ],
          ),
        ),
      );
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String username;
  const _HeroBanner({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.blue,
      child: Stack(
        children: [
          // Subtle circle decoration top-right
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 60,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sparkle + label
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'WELCOME BACK',
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        username,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Complete quizzes to earn\nstars and coins!',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mascot
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: SizedBox(
                    width: 80,
                    height: 142,
                    child: SvgPicture.asset(
                      'assets/images/mascot.svg',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
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

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Quizzes',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See all',
                  style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.blue, size: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quest card (category) ────────────────────────────────────────────────────

class _QuestCard extends StatefulWidget {
  final CategoryModel category;
  final List<TopicModel> topics;
  final UserModel? user;
  final bool isGuest;
  final Future<int> Function(UserModel, String, List<TopicModel>)
      completedTopics;
  final VoidCallback onTap;

  const _QuestCard({
    required this.category,
    required this.topics,
    required this.user,
    required this.isGuest,
    required this.completedTopics,
    required this.onTap,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  Future<int>? _progressFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(_QuestCard old) {
    super.didUpdateWidget(old);
    if (old.user?.id != widget.user?.id ||
        old.category.id != widget.category.id ||
        old.user?.answeredQuestions.length !=
            widget.user?.answeredQuestions.length) {
      _initFuture();
    }
  }

  void _initFuture() {
    _progressFuture =
        (!widget.isGuest && widget.user != null && widget.topics.isNotEmpty)
            ? widget.completedTopics(
                widget.user!, widget.category.id, widget.topics)
            : null;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppCategoryIcon.colorFor(widget.category.title);
    final icon = AppCategoryIcon.iconFor(widget.category.title);
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
          splashColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),

                const SizedBox(width: 14),

                // Name + progress
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
                      const SizedBox(height: 6),
                      if (_progressFuture != null)
                        FutureBuilder<int>(
                          future: _progressFuture,
                          builder: (_, snap) {
                            final done = snap.data ?? 0;
                            final progress = total == 0 ? 0.0 : done / total;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(
                                        '${widget.category.id}_${widget.user?.answeredQuestions.length}'),
                                    tween: Tween(begin: 0, end: progress),
                                    duration:
                                        const Duration(milliseconds: 900),
                                    curve: Curves.easeOut,
                                    builder: (_, v, __) =>
                                        LinearProgressIndicator(
                                      value: v,
                                      minHeight: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  snap.connectionState ==
                                          ConnectionState.waiting
                                      ? '$total topics'
                                      : '${snap.data ?? 0} / $total topics done',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Star reward indicator
                Column(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      'Stars',
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
  }
}

// ─── Practice card ────────────────────────────────────────────────────────────

class _PracticeCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PracticeCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center_rounded,
                      color: AppColors.orange, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Weak Spots',
                      style: GoogleFonts.nunito(
                        color: AppColors.orangeDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$count question${count == 1 ? '' : 's'} to review · +3 coins',
                      style: GoogleFonts.nunito(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Practice',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _QuestCardSkeleton extends StatelessWidget {
  const _QuestCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(18),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1000.ms);
  }
}
