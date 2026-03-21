import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_result_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultModel result;

  const QuizResultScreen({super.key, required this.result});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    // Save quiz result
    await QuestionService().saveResult(widget.result);

    // Save correctly answered question IDs to prevent farming
    if (widget.result.correctlyAnsweredIds.isNotEmpty) {
      await QuestionService().saveAnsweredQuestions(
        userId: user.id,
        questionIds: widget.result.correctlyAnsweredIds,
      );
    }

    // Add stars
    await QuestionService().addStars(
      userId: user.id,
      starsToAdd: widget.result.starsEarned,
    );

    // Refresh user
    await auth.refreshUser();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final pct = result.percentage;

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Result emoji
                Text(
                  result.starsEarned == 3
                      ? '🏆'
                      : result.starsEarned == 2
                      ? '🌟'
                      : result.starsEarned == 1
                      ? '🙂'
                      : '😔',
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  result.starsEarned == 0
                      ? 'Keep Trying!'
                      : result.starsEarned == 1
                      ? 'Good Job!'
                      : result.starsEarned == 2
                      ? 'Great Job!'
                      : 'Perfect Score!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.categoryName,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        i < result.starsEarned ? '⭐' : '☆',
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('✅', '${result.score}/${result.totalQuestions}', 'Correct'),
                      _stat('📊', '$pct%', 'Score'),
                      _stat('⭐', '+${result.starsEarned}', 'Stars Earned'),
                      _stat('🏆', '${result.pointsEarned}', 'Points'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Back to Topics',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}