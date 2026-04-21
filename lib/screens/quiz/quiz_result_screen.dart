import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/quiz_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final pct = result.percentage;
    final isGreat = result.starsEarned >= 2;
    final isThree = result.starsEarned == 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Trophy Lottie for perfect score, emoji otherwise
                  if (isThree)
                    Lottie.asset(
                      'assets/lottie/trophy.json',
                      controller: _trophyCtrl,
                      width: 140,
                      height: 140,
                      onLoaded: (comp) {
                        _trophyCtrl.duration = comp.duration;
                        _trophyCtrl.forward();
                      },
                    )
                  else
                    Text(
                      result.starsEarned == 2
                          ? '🌟'
                          : result.starsEarned == 1
                              ? '🙂'
                              : '😔',
                      style: const TextStyle(fontSize: 72),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          curve: Curves.elasticOut,
                          duration: const Duration(milliseconds: 600),
                        ),

                  const SizedBox(height: 12),

                  Text(
                    result.starsEarned == 0
                        ? 'Keep Trying!'
                        : result.starsEarned == 1
                            ? 'Good Job!'
                            : result.starsEarned == 2
                                ? 'Great Job!'
                                : 'Perfect Score!',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 200))
                      .fadeIn(duration: const Duration(milliseconds: 300))
                      .slideY(
                          begin: 0.1,
                          end: 0,
                          duration: const Duration(milliseconds: 300)),

                  const SizedBox(height: 4),
                  Text(
                    result.categoryName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
                  )
                      .animate(delay: const Duration(milliseconds: 300))
                      .fadeIn(duration: const Duration(milliseconds: 250)),

                  const SizedBox(height: 28),

                  // Staggered star reveal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          i < result.starsEarned ? '⭐' : '☆',
                          style: const TextStyle(fontSize: 40),
                        )
                            .animate(
                                delay: Duration(milliseconds: 400 + i * 200))
                            .scale(
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut,
                              duration: const Duration(milliseconds: 600),
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('✅', '${result.score}/${result.totalQuestions}',
                            'Correct'),
                        _divider(),
                        _stat('📊', '$pct%', 'Score'),
                        _divider(),
                        _stat('⭐', '+${result.starsEarned}', 'Stars'),
                        _divider(),
                        _stat('🏆', '${result.pointsEarned}', 'Points'),
                      ],
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 600))
                      .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut)
                      .fadeIn(duration: const Duration(milliseconds: 400)),

                  const SizedBox(height: 32),

                  // Motivational message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isGreat
                          ? AppColors.correct.withOpacity(0.08)
                          : AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isGreat
                            ? AppColors.correct.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      isGreat
                          ? '🚀 Amazing work! You\'re becoming a true internet safety hero!'
                          : '💪 Keep practicing — every question makes you safer online!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isGreat ? AppColors.correct : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  )
                      .animate(delay: const Duration(milliseconds: 800))
                      .fadeIn(duration: const Duration(milliseconds: 350)),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('Back to Topics'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Try Again',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Full-screen confetti overlay (auto-hides when done)
          if (_showConfetti)
            IgnorePointer(
              child: Lottie.asset(
                'assets/lottie/confetti.json',
                controller: _confettiCtrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                onLoaded: (comp) {
                  _confettiCtrl.duration = comp.duration;
                  _confettiCtrl.forward();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: const Color(0xFFE5E7EB),
      );
}
