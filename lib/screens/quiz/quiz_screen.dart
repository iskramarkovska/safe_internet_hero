import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/question_model.dart';
import '../../models/enums.dart';
import '../../models/quiz_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import '../../widgets/app_widgets.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String topicId;
  final String topicName;
  final Color color;

  /// When true, loads all questions ignoring already-answered ones.
  final bool forReplay;

  /// When provided, loads these specific question IDs (practice / review mode).
  final List<String>? specificIds;

  const QuizScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.topicId,
    required this.topicName,
    required this.color,
    this.forReplay = false,
    this.specificIds,
  });

  bool get isPractice => specificIds != null;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuestionService _questionService = QuestionService();
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _totalPoints = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _isLoading = true;
  final Map<int, bool> _answeredCorrectly = {};

  static const _sheetHeight = 230.0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    List<QuestionModel> questions;

    if (widget.isPractice) {
      questions =
          await _questionService.getQuestionsByIds(widget.specificIds!);
    } else {
      final user = context.read<AuthProvider>().user;
      questions = await _questionService.getQuestions(
        categoryId: widget.categoryId,
        topicId: widget.topicId,
        excludeIds:
            widget.forReplay ? [] : (user?.answeredQuestions ?? []),
      );
    }

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final isCorrect = index == _questions[_currentIndex].correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _answeredCorrectly[_currentIndex] = isCorrect;
      if (isCorrect) {
        _score++;
        _totalPoints += _questions[_currentIndex].points;
      }
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  int _calculateStars(int score, int total) {
    if (total == 0) return 0;
    final pct = score / total;
    if (pct == 1.0) return 3;
    if (pct >= 0.8) return 2;
    if (pct >= 0.5) return 1;
    return 0;
  }

  void _finish() {
    final user = context.read<AuthProvider>().user;

    final correctIds = _questions
        .asMap()
        .entries
        .where((e) => _answeredCorrectly[e.key] == true)
        .map((e) => e.value.id)
        .toList();

    final incorrectIds = _questions
        .where((q) => !correctIds.contains(q.id))
        .map((q) => q.id)
        .toList();

    final stars = _calculateStars(_score, _questions.length);

    // Practice mode: small flat coin reward, no stars saved.
    // Normal mode: coins scale with stars earned.
    final coinsEarned =
        widget.isPractice ? 3 : stars * 5;

    final result = QuizResultModel(
      id: '',
      userId: user?.id ?? '',
      username: user?.username ?? '',
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
      topicId: widget.topicId,
      topicName: widget.topicName,
      score: _score,
      totalQuestions: _questions.length,
      starsEarned: stars,
      coinsEarned: coinsEarned,
      pointsEarned: _totalPoints,
      completedAt: DateTime.now(),
      correctlyAnsweredIds: correctIds,
      incorrectlyAnsweredIds: incorrectIds,
    );

    final catId = widget.categoryId;
    final catName = widget.categoryName;
    final topId = widget.topicId;
    final topName = widget.topicName;
    final color = widget.color;
    final isPractice = widget.isPractice;

    Navigator.pushReplacement(
      context,
      AppPageRoute(
        builder: (ctx) => QuizResultScreen(
          result: result,
          onPracticeAgain: isPractice
              ? null
              : () => Navigator.of(ctx).pushReplacement(
                    AppPageRoute(
                      builder: (_) => QuizScreen(
                        categoryId: catId,
                        categoryName: catName,
                        topicId: topId,
                        topicName: topName,
                        color: color,
                        forReplay: true,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Color _answerBg(int index) {
    if (!_answered) return Colors.white;
    final q = _questions[_currentIndex];
    if (index == q.correctIndex) return AppColors.greenLight;
    if (index == _selectedAnswer) return AppColors.redLight;
    return Colors.white;
  }

  Color _answerBorder(int index) {
    if (!_answered) return AppColors.border;
    final q = _questions[_currentIndex];
    if (index == q.correctIndex) return AppColors.green;
    if (index == _selectedAnswer) return AppColors.red;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _questions.isEmpty
                ? _buildEmpty()
                : _buildQuiz(),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        // Skeleton top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
          child: Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Column(
                  children: [
                    _SkeletonBox(width: 100, height: 14, radius: 7),
                    const SizedBox(height: 4),
                    _SkeletonBox(width: 80, height: 12, radius: 6),
                  ],
                ),
              ),
              _SkeletonBox(width: 56, height: 32, radius: 16),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SkeletonBox(width: double.infinity, height: 10, radius: 8),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SkeletonBox(width: double.infinity, height: 100, radius: 16),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _SkeletonBox(
                width: double.infinity, height: 68, radius: 16),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: const Duration(milliseconds: 1000));
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.blue, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'All done here!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve answered all available questions.\nCome back for more soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Play Again',
              variant: AppButtonVariant.primary,
              icon: Icons.replay_rounded,
              onTap: () => Navigator.pushReplacement(
                context,
                AppPageRoute(
                  builder: (_) => QuizScreen(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                    topicId: widget.topicId,
                    topicName: widget.topicName,
                    color: widget.color,
                    forReplay: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Go Back',
              variant: AppButtonVariant.secondary,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final letters = ['A', 'B', 'C', 'D'];
    final progress = (_currentIndex + 1) / _questions.length;
    final isCorrect =
        _answered && _selectedAnswer == question.correctIndex;

    return Stack(
      children: [
        // ── Main quiz content ─────────────────────────────────────────────
        Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 24),
                    onPressed: () => _confirmQuit(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.isPractice
                              ? '⚡ Practice Mode'
                              : widget.topicName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Question ${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Score chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.gold, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          '$_score',
                          style: const TextStyle(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_currentIndex),
                  tween: Tween(
                      begin: _currentIndex / _questions.length,
                      end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isPractice
                            ? AppColors.orange
                            : AppColors.blue),
                    minHeight: 10,
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, _answered ? _sheetHeight + 16 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Difficulty badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${question.difficulty.name[0].toUpperCase()}${question.difficulty.name.substring(1)} · +${question.points} pts',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question card
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        question.text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Answer options
                    ...List.generate(question.options.length, (index) {
                      final optIsCorrect =
                          _answered && index == question.correctIndex;
                      final optIsWrong = _answered &&
                          index == _selectedAnswer &&
                          !optIsCorrect;

                      Widget option = GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: _answerBg(index),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _answerBorder(index),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _answered
                                      ? (optIsCorrect
                                          ? AppColors.green
                                          : optIsWrong
                                              ? AppColors.red
                                              : AppColors.border)
                                      : AppColors.blueLight,
                                  border: Border.all(
                                    color: _answered
                                        ? (optIsCorrect
                                            ? AppColors.green
                                            : optIsWrong
                                                ? AppColors.red
                                                : AppColors.borderDark)
                                        : AppColors.blue
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Center(
                                  child: _answered
                                      ? Icon(
                                          optIsCorrect
                                              ? Icons.check_rounded
                                              : optIsWrong
                                                  ? Icons.close_rounded
                                                  : null,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : Text(
                                          question.type ==
                                                  QuestionType.trueFalse
                                              ? (index == 0 ? 'T' : 'F')
                                              : letters[index],
                                          style: const TextStyle(
                                            color: AppColors.blue,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    color: optIsCorrect
                                        ? AppColors.greenDark
                                        : optIsWrong
                                            ? AppColors.redDark
                                            : AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (optIsWrong) {
                        return option
                            .animate(
                                key: ValueKey(
                                    'wrong_${_currentIndex}_$index'))
                            .shake(
                              duration: const Duration(milliseconds: 450),
                              hz: 4,
                              offset: const Offset(8, 0),
                            );
                      }
                      if (optIsCorrect) {
                        return option
                            .animate(
                                key: ValueKey(
                                    'correct_${_currentIndex}_$index'))
                            .scale(
                              begin: const Offset(1.04, 1.04),
                              end: const Offset(1, 1),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.elasticOut,
                            );
                      }
                      return option;
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Explanation bottom sheet ──────────────────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          bottom: _answered ? 0 : -_sheetHeight,
          left: 0,
          right: 0,
          child: _ExplanationSheet(
            isCorrect: isCorrect,
            explanation: _answered
                ? _questions[_currentIndex].explanation
                : '',
            isLast: _currentIndex >= _questions.length - 1,
            onContinue: _next,
          ),
        ),
      ],
    );
  }

  void _confirmQuit(BuildContext context) {
    showDialog(
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
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.redLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.exit_to_app_rounded,
                      color: AppColors.red, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quit Quiz?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your progress will be lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Keep Going',
                        variant: AppButtonVariant.success,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Quit',
                        variant: AppButtonVariant.danger,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
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

// ─── Skeleton box ──────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Explanation bottom sheet ──────────────────────────────────────────────────

class _ExplanationSheet extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final bool isLast;
  final VoidCallback onContinue;

  const _ExplanationSheet({
    required this.isCorrect,
    required this.explanation,
    required this.isLast,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.green : AppColors.red;
    final darkColor = isCorrect ? AppColors.greenDark : AppColors.redDark;
    final icon =
        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = isCorrect ? 'Correct!' : 'Not quite...';
    final continueLabel = isLast ? 'See Results' : 'Continue';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onContinue,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: darkColor.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Text(
                continueLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
