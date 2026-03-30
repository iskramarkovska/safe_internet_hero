import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/question_model.dart';
import '../../models/enums.dart';
import '../../models/quiz_result_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/questions_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String topicId;
  final String topicName;
  final Color color;

  const QuizScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.topicId,
    required this.topicName,
    required this.color,
  });

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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final user = context.read<AuthProvider>().user;
    final questions = await _questionService.getQuestions(
      categoryId: widget.categoryId,
      topicId: widget.topicId,
      excludeIds: user?.answeredQuestions ?? [],
    );
    setState(() {
      _questions = questions..shuffle();
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

  void _finish() {
    final user = context.read<AuthProvider>().user;
    final correctIds = _questions
        .asMap()
        .entries
        .where((e) => _answeredCorrectly[e.key] == true)
        .map((e) => e.value.id)
        .toList();

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
      starsEarned: _score,
      pointsEarned: _totalPoints,
      completedAt: DateTime.now(),
      correctlyAnsweredIds: correctIds,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QuizResultScreen(result: result)),
    );
  }

  Color _answerBg(int index) {
    if (!_answered) return Colors.white;
    if (index == _questions[_currentIndex].correctIndex) {
      return AppColors.correct.withOpacity(0.12);
    }
    if (index == _selectedAnswer) return AppColors.wrong.withOpacity(0.12);
    return Colors.white;
  }

  Color _answerBorder(int index) {
    if (!_answered) return const Color(0xFFE5E7EB);
    if (index == _questions[_currentIndex].correctIndex) {
      return AppColors.correct;
    }
    if (index == _selectedAnswer) return AppColors.wrong;
    return const Color(0xFFE5E7EB);
  }

  Color _answerIcon(int index) {
    if (index == _questions[_currentIndex].correctIndex) {
      return AppColors.correct;
    }
    if (index == _selectedAnswer) return AppColors.wrong;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
            ? _buildEmpty()
            : _buildQuiz(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No questions available yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
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

    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Quit Quiz?'),
                    content:
                    const Text('Your progress will be lost.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Keep Playing'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Quit',
                            style: TextStyle(color: AppColors.wrong)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(widget.topicName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    Text(
                      'Q${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('✓ ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.correct)),
                    Text('$_score',
                        style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              minHeight: 6,
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${question.difficulty.name[0].toUpperCase()}${question.difficulty.name.substring(1)} · +${question.points} pts',
                    style: TextStyle(
                        color: widget.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Answer options
                ...List.generate(question.options.length, (index) {
                  final isCorrect =
                      _answered && index == question.correctIndex;
                  final isWrong = _answered &&
                      index == _selectedAnswer &&
                      !isCorrect;

                  return GestureDetector(
                    onTap: () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _answerBg(index),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _answerBorder(index), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _answered
                                  ? _answerIcon(index).withOpacity(0.15)
                                  : const Color(0xFFF3F4F6),
                              border: Border.all(
                                  color: _answered
                                      ? _answerIcon(index)
                                      : const Color(0xFFE5E7EB)),
                            ),
                            child: Center(
                              child: _answered
                                  ? Icon(
                                isCorrect
                                    ? Icons.check_rounded
                                    : isWrong
                                    ? Icons.close_rounded
                                    : null,
                                color: _answerIcon(index),
                                size: 16,
                              )
                                  : Text(
                                question.type ==
                                    QuestionType.trueFalse
                                    ? (index == 0 ? 'T' : 'F')
                                    : letters[index],
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              question.options[index],
                              style: TextStyle(
                                color: isCorrect
                                    ? AppColors.correct
                                    : isWrong
                                    ? AppColors.wrong
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isCorrect
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Explanation
                if (_answered) ...[
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (_selectedAnswer == question.correctIndex
                          ? AppColors.correct
                          : AppColors.wrong)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_selectedAnswer == question.correctIndex
                            ? AppColors.correct
                            : AppColors.wrong)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAnswer == question.correctIndex
                              ? '🎉'
                              : '💡',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            question.explanation,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Next Question'
                            : 'See Results',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}