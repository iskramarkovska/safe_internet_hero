import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_service.dart';
import '../auth/splash_screen.dart';

class ArticleScreen extends StatefulWidget {
  final LearningContentModel content;
  const ArticleScreen({super.key, required this.content});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final _scrollController = ScrollController();
  final _learningService = LearningService();

  double _readProgress = 0;
  bool _completionTriggered = false;
  bool _completionVisible = false;
  bool _completionLoading = false;
  // null = loading/pending, 0 = already read before, >0 = just earned
  int? _xpEarned;

  int get _xpAmount =>
      (widget.content.readTimeMinutes * 2).clamp(4, 20).toInt() == 0
          ? 5
          : (widget.content.readTimeMinutes * 2).clamp(4, 20);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Short articles that don't require scrolling complete after 3 s of reading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 20) {
        Future.delayed(const Duration(seconds: 3), _triggerCompletion);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress = (_scrollController.offset / max).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.005) {
      setState(() => _readProgress = progress);
    }
    if (progress >= 0.85) _triggerCompletion();
  }

  void _triggerCompletion() {
    if (_completionTriggered) return;
    _completionTriggered = true;
    _handleCompletion();
  }

  Future<void> _handleCompletion() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    setState(() => _completionVisible = true);

    if (auth.isGuest) return; // guest card renders without XP

    final user = auth.user;
    if (user == null) return;

    setState(() => _completionLoading = true);
    try {
      final earned = await _learningService.markContentRead(
        userId: user.id,
        contentId: widget.content.id,
        xpToAward: _xpAmount,
      );
      if (!mounted) return;
      setState(() {
        _xpEarned = earned;
        _completionLoading = false;
      });
      if (earned > 0) auth.refreshUser();
    } catch (_) {
      if (!mounted) return;
      setState(() => _completionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthProvider>().isGuest;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Fixed top bar ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.content.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Reading progress bar
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _readProgress),
                  duration: const Duration(milliseconds: 150),
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.green),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  widget.content.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          widget.content.thumbnailUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ArticlePlaceholder(),
                        )
                      : const _ArticlePlaceholder(),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(children: [
                          _Badge(
                            label: 'ARTICLE',
                            icon: Icons.article_rounded,
                            color: AppColors.teal,
                          ),
                          if (widget.content.readTimeMinutes > 0) ...[
                            const SizedBox(width: 8),
                            _Badge(
                              label: '${widget.content.readTimeMinutes} MIN READ',
                              icon: Icons.access_time_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ]),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.content.title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),

                        // Description callout
                        if (widget.content.description.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.blueLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.blue
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              widget.content.description,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: AppColors.border,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Body
                        Text(
                          widget.content.content,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Completion card — slides in after reading
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: _completionVisible
                              ? _CompletionCard(
                                  isGuest: isGuest,
                                  isLoading: _completionLoading,
                                  xpEarned: _xpEarned,
                                  xpAmount: _xpAmount,
                                  onCreateAccount: () {
                                    context
                                        .read<AuthProvider>()
                                        .exitGuestMode();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      AppPageRoute(
                                          builder: (_) =>
                                              const LandingScreen()),
                                      (r) => false,
                                    );
                                  },
                                )
                                    .animate()
                                    .scale(
                                      begin: const Offset(0.92, 0.92),
                                      end: const Offset(1, 1),
                                      curve: Curves.elasticOut,
                                      duration: 600.ms,
                                    )
                                    .fadeIn(duration: 300.ms)
                              : const SizedBox.shrink(),
                        ),
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
}

// ─── Placeholder ──────────────────────────────────────────────────────────────

class _ArticlePlaceholder extends StatelessWidget {
  const _ArticlePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, Color(0xFF4DD0C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.article_rounded,
            color: Colors.white.withValues(alpha: 0.5), size: 80),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.nunito(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }
}

// ─── Completion card ──────────────────────────────────────────────────────────

class _CompletionCard extends StatelessWidget {
  final bool isGuest;
  final bool isLoading;
  final int? xpEarned;
  final int xpAmount;
  final VoidCallback onCreateAccount;

  const _CompletionCard({
    required this.isGuest,
    required this.isLoading,
    required this.xpEarned,
    required this.xpAmount,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) return _GuestCard(onCreateAccount: onCreateAccount);
    if (isLoading || xpEarned == null) return _LoadingCard();
    if (xpEarned! == 0) return const _AlreadyReadCard();
    return _EarnedCard(xp: xpEarned!);
  }
}

class _EarnedCard extends StatelessWidget {
  final int xp;
  const _EarnedCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF46A302)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Article Complete!',
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Great job! Keep exploring to level up.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('+$xp XP earned',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _AlreadyReadCard extends StatelessWidget {
  const _AlreadyReadCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.blue.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.blue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Already completed',
                    style: GoogleFonts.nunito(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 15)),
                Text('You already earned XP for this article.',
                    style: GoogleFonts.nunito(
                        color: AppColors.blue.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: AppColors.green, strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestCard({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF5AB4F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_open_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 10),
          Text('Want to earn XP for reading?',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              'Create a free account to save your progress\nand earn XP for every article you read.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCreateAccount,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blueDark.withValues(alpha: 0.4),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text('Create Free Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
