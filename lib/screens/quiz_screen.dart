import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../models/enums.dart';
import '../models/quiz_result_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';
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

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  int _calculateStars() => _score;

  void _finishQuiz() {
    final user = context.read<AuthProvider>().user;
    final stars = _calculateStars();

    // Collect IDs of correctly answered questions only
    final correctlyAnsweredIds = _questions
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
      starsEarned: stars,
      pointsEarned: _totalPoints,
      completedAt: DateTime.now(),
      correctlyAnsweredIds: correctlyAnsweredIds,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => QuizResultScreen(result: result)),
    );
  }

  Color _getAnswerColor(int index) {
    if (!_answered) return Colors.white.withOpacity(0.08);
    final correct = _questions[_currentIndex].correctIndex;
    if (index == correct) return Colors.green.withOpacity(0.3);
    if (index == _selectedAnswer) return Colors.red.withOpacity(0.3);
    return Colors.white.withOpacity(0.05);
  }

  Color _getAnswerBorderColor(int index) {
    if (!_answered) return Colors.white.withOpacity(0.2);
    final correct = _questions[_currentIndex].correctIndex;
    if (index == correct) return Colors.green;
    if (index == _selectedAnswer) return Colors.red;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _questions.isEmpty
              ? _buildEmpty()
              : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No questions available yet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentIndex];
    final letters = ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E),
                    title: const Text('Quit Quiz?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text('Your progress will be lost.',
                        style: TextStyle(color: Colors.white70)),
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
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      widget.topicName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      'Q${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_score ✓',
                  style: TextStyle(
                      color: widget.color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),

          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${question.difficulty.name} · +${question.points} pts',
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
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: widget.color.withOpacity(0.3), width: 1.5),
            ),
            child: Text(
              question.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final isCorrect =
                    _answered && index == question.correctIndex;
                final isWrong = _answered &&
                    index == _selectedAnswer &&
                    !isCorrect;

                return GestureDetector(
                  onTap: () => _selectAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _getAnswerColor(index),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _getAnswerBorderColor(index), width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrect
                                ? Colors.green
                                : isWrong
                                ? Colors.red
                                : Colors.white.withOpacity(0.15),
                          ),
                          child: Center(
                            child: isCorrect
                                ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                                : isWrong
                                ? const Icon(Icons.close,
                                color: Colors.white, size: 18)
                                : Text(
                              question.type ==
                                  QuestionType.trueFalse
                                  ? (index == 0 ? 'T' : 'F')
                                  : letters[index],
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.green
                                  : isWrong
                                  ? Colors.red
                                  : Colors.white,
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
              },
            ),
          ),

          // Explanation + Next button
          if (_answered) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_selectedAnswer == question.correctIndex
                    ? Colors.green
                    : Colors.red)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_selectedAnswer == question.correctIndex
                      ? Colors.green
                      : Colors.red)
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAnswer == question.correctIndex ? '🎉' : '💡',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}