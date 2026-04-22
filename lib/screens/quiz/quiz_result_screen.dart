import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/quiz_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import '../../widgets/app_widgets.dart';
import '../home/main_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultModel result;

  const QuizResultScreen({super.key, required this.result});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _trophyCtrl;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(vsync: this);
    _trophyCtrl = AnimationController(vsync: this);

    if (widget.result.starsEarned >= 2) {
      _showConfetti = true;
      _confettiCtrl.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showConfetti = false);
        }
      });
    }

    _saveResult();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _trophyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveResult() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    await QuestionService().saveResult(widget.result);
    if (widget.result.correctlyAnsweredIds.isNotEmpty) {
      await QuestionService().saveAnsweredQuestions(
        userId: user.id,
        questionIds: widget.result.correctlyAnsweredIds,
      );
    }
    await QuestionService()
        .addStars(userId: user.id, starsToAdd: widget.result.starsEarned);
    await auth.refreshUser();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void _practiceAgain() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final pct = result.percentage;
    final isGreat = result.starsEarned >= 2;
    final isThree = result.starsEarned == 3;
    final xp = result.starsEarned;
    final coins = result.starsEarned * 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  // Hero icon / trophy
                  if (isThree)
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Lottie.asset(
                        'assets/lottie/trophy.json',
                        controller: _trophyCtrl,
                        onLoaded: (comp) {
                          _trophyCtrl.duration = comp.duration;
                          _trophyCtrl.forward();
                        },
                      ),
                    )
                  else
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGreat
                            ? AppColors.greenLight
                            : AppColors.blueLight,
                      ),
                      child: Center(
                        child: Icon(
                          isGreat
                              ? Icons.emoji_events_rounded
                              : Icons.sentiment_neutral_rounded,
                          size: 60,
                          color: isGreat
                              ? AppColors.green
                              : AppColors.blue,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                          duration: const Duration(milliseconds: 700),
                        ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    result.starsEarned == 0
                        ? 'Keep Trying!'
                        : result.starsEarned == 1
                            ? 'Good Job!'
                            : result.starsEarned == 2
                                ? 'Great Work!'
                                : 'Perfect Score!',
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 4),

                  Text(
                    result.categoryName,
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 250.ms),

                  const SizedBox(height: 32),

                  // ── Star reveal ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final earned = i < result.starsEarned;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star_rounded,
                          size: earned ? 52 : 44,
                          color: earned
                              ? AppColors.gold
                              : AppColors.borderDark,
                        )
                            .animate(delay: Duration(milliseconds: 400 + i * 200))
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                              duration: const Duration(milliseconds: 600),
                            ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // ── XP + Coins ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _EarnedChip(
                          icon: Icons.star_rounded,
                          label: '+$xp XP',
                          color: AppColors.gold,
                          delay: 900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EarnedChip(
                          icon: Icons.monetization_on_rounded,
                          label: '+$coins Coins',
                          color: AppColors.orange,
                          delay: 1050,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Stats card ─────────────────────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCell(
                          icon: Icons.check_circle_rounded,
                          color: AppColors.green,
                          value:
                              '${result.score}/${result.totalQuestions}',
                          label: 'Correct',
                        ),
                        Container(
                            width: 1,
                            height: 44,
                            color: AppColors.border),
                        _StatCell(
                          icon: Icons.bar_chart_rounded,
                          color: AppColors.blue,
                          value: '$pct%',
                          label: 'Score',
                        ),
                        Container(
                            width: 1,
                            height: 44,
                            color: AppColors.border),
                        _StatCell(
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.gold,
                          value: '${result.pointsEarned}',
                          label: 'Points',
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 700.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: const Duration(milliseconds: 400)),

                  const SizedBox(height: 14),

                  // ── Motivational message ────────────────────────────────────
                  AppCard(
                    color: isGreat ? AppColors.greenLight : AppColors.blueLight,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          isGreat ? Icons.rocket_launch_rounded : Icons.fitness_center_rounded,
                          color: isGreat ? AppColors.greenDark : AppColors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isGreat
                                ? 'Amazing work! You\'re becoming a true internet safety hero!'
                                : 'Keep practicing — every question makes you safer online!',
                            style: GoogleFonts.nunito(
                              color: isGreat
                                  ? AppColors.greenDark
                                  : AppColors.blue,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 900.ms)
                      .fadeIn(duration: const Duration(milliseconds: 350)),

                  const SizedBox(height: 32),

                  // ── Actions ────────────────────────────────────────────────
                  AppButton(
                    label: 'Continue',
                    variant: AppButtonVariant.primary,
                    icon: Icons.home_rounded,
                    onTap: _goHome,
                  )
                      .animate(delay: 1000.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  AppButton(
                    label: 'Practice Again',
                    variant: AppButtonVariant.secondary,
                    onTap: _practiceAgain,
                  )
                      .animate(delay: 1100.ms)
                      .fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),

          // ── Confetti overlay (non-blocking) ─────────────────────────────────
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/lottie/confetti.json',
                  controller: _confettiCtrl,
                  fit: BoxFit.cover,
                  onLoaded: (comp) {
                    _confettiCtrl.duration = comp.duration;
                    _confettiCtrl.forward();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _EarnedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;

  const _EarnedChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 350))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 500),
        );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
