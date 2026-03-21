import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums.dart';
import '../models/question_model.dart';
import '../services/questions_service.dart';
import 'admin_content_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _explanationController = TextEditingController();
  final _option0Controller = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();

  String _categoryId = 'privacy';
  String _topicId = 'personal_info';
  QuestionType _type = QuestionType.multipleChoice;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  int _correctIndex = 0;
  bool _isSaving = false;

  final Map<String, List<String>> _categoryTopics = {
    'privacy': [
      'personal_info',
      'sharing_online',
      'digital_footprint',
      'app_permissions'
    ],
    'passwords': [
      'strong_passwords',
      'two_factor_auth',
      'password_safety',
      'password_manager'
    ],
    'cyberbullying': [
      'spot_bullying',
      'be_an_upstander',
      'report_block',
      'cyber_law'
    ],
    'social_media': [
      'privacy_settings',
      'strangers_online',
      'geo_tagging',
      'screen_time'
    ],
    'phishing': [
      'spot_scams',
      'fake_links',
      'email_safety',
      'spear_phishing'
    ],
  };

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    _option0Controller.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    super.dispose();
  }

  List<String> get _options {
    if (_type == QuestionType.trueFalse) {
      return ['True', 'False'];
    }
    return [
      _option0Controller.text.trim(),
      _option1Controller.text.trim(),
      _option2Controller.text.trim(),
      _option3Controller.text.trim(),
    ];
  }

  int get _pointsForDifficulty {
    switch (_difficulty) {
      case DifficultyLevel.beginner: return 10;
      case DifficultyLevel.intermediate: return 20;
      case DifficultyLevel.advanced: return 30;
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == QuestionType.multipleChoice) {
      if (_option0Controller.text.trim().isEmpty ||
          _option1Controller.text.trim().isEmpty ||
          _option2Controller.text.trim().isEmpty ||
          _option3Controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all 4 options'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final question = QuestionModel(
        id: '',
        categoryId: _categoryId,
        topicId: _topicId,
        text: _textController.text.trim(),
        type: _type,
        options: _options,
        correctIndex: _correctIndex,
        explanation: _explanationController.text.trim(),
        difficulty: _difficulty,
        points: _pointsForDifficulty,
      );

      await QuestionService().seedQuestions([question]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _textController.clear();
      _explanationController.clear();
      _option0Controller.clear();
      _option1Controller.clear();
      _option2Controller.clear();
      _option3Controller.clear();
      setState(() {
        _correctIndex = 0;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '⚙️ Admin — Add Question',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminQuestionsListScreen()),
            ),
            icon: const Icon(Icons.list, color: Color(0xFF00D4FF)),
            label: const Text('View All',
                style: TextStyle(color: Color(0xFF00D4FF))),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminContentScreen()),
            ),
            icon: const Icon(Icons.book_outlined, color: Color(0xFF00D4FF)),
            label: const Text('Add Content',
                style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // Category picker
            _sectionLabel('Category'),
            DropdownButtonFormField<String>(
              value: _categoryId,
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Select category'),
              items: _categoryTopics.keys.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (val) => setState(() {
                _categoryId = val!;
                _topicId = _categoryTopics[val]!.first;
              }),
            ),
            const SizedBox(height: 16),

            // Topic picker
            _sectionLabel('Topic'),
            DropdownButtonFormField<String>(
              value: _topicId,
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Select topic'),
              items: (_categoryTopics[_categoryId] ?? []).map((topic) =>
                  DropdownMenuItem(
                    value: topic,
                    child: Text(topic),
                  )).toList(),
              onChanged: (val) => setState(() => _topicId = val!),
            ),
            const SizedBox(height: 16),

            // Question type
            _sectionLabel('Question type'),
            Row(
              children: [
                Expanded(
                  child: _typeButton(
                    'Multiple Choice',
                    QuestionType.multipleChoice,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _typeButton(
                    'True / False',
                    QuestionType.trueFalse,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Difficulty
            _sectionLabel('Difficulty'),
            Row(
              children: [
                Expanded(child: _difficultyButton('Beginner', DifficultyLevel.beginner, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _difficultyButton('Intermediate', DifficultyLevel.intermediate, Colors.orange)),
                const SizedBox(width: 8),
                Expanded(child: _difficultyButton('Advanced', DifficultyLevel.advanced, Colors.red)),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            _sectionLabel('Question'),
            TextFormField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Type your question here...'),
              validator: (val) =>
              val == null || val.isEmpty ? 'Question is required' : null,
            ),
            const SizedBox(height: 16),

            // Options (only for multiple choice)
            if (_type == QuestionType.multipleChoice) ...[
              _sectionLabel('Answer options'),
              _optionField(_option0Controller, 'Option A', 0),
              const SizedBox(height: 10),
              _optionField(_option1Controller, 'Option B', 1),
              const SizedBox(height: 10),
              _optionField(_option2Controller, 'Option C', 2),
              const SizedBox(height: 10),
              _optionField(_option3Controller, 'Option D', 3),
            ],

            // Correct answer for True/False
            if (_type == QuestionType.trueFalse) ...[
              _sectionLabel('Correct answer'),
              Row(
                children: [
                  Expanded(child: _correctButton('True', 0)),
                  const SizedBox(width: 12),
                  Expanded(child: _correctButton('False', 1)),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Explanation
            _sectionLabel('Explanation (shown after answering)'),
            TextFormField(
              controller: _explanationController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Why is this answer correct?'),
              validator: (val) =>
              val == null || val.isEmpty ? 'Explanation is required' : null,
            ),
            const SizedBox(height: 8),

            // Points preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This question will award $_pointsForDifficulty points',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                  'Save Question',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 14),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
    ),
  );

  Widget _typeButton(String label, QuestionType type) => GestureDetector(
    onTap: () => setState(() {
      _type = type;
      _correctIndex = 0;
    }),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _type == type
            ? const Color(0xFF00D4FF).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _type == type
              ? const Color(0xFF00D4FF)
              : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _type == type ? const Color(0xFF00D4FF) : Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    ),
  );

  Widget _difficultyButton(String label, DifficultyLevel level, Color color) =>
      GestureDetector(
        onTap: () => setState(() => _difficulty = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _difficulty == level
                ? color.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _difficulty == level ? color : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _difficulty == level ? color : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );

  Widget _optionField(
      TextEditingController controller, String label, int index) {
    final isCorrect = _correctIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _correctIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? Colors.green : Colors.white24,
            width: isCorrect ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 52,
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.3)
                    : Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  isCorrect ? '✓' : label.split(' ')[1],
                  style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.white38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '$label — tap to mark as correct',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _correctButton(String label, int index) => GestureDetector(
    onTap: () => setState(() => _correctIndex = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _correctIndex == index
            ? Colors.green.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _correctIndex == index ? Colors.green : Colors.white24,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _correctIndex == index ? Colors.green : Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    ),
  );
}

// ── Questions list screen ─────────────────────────────────────────────────────

class AdminQuestionsListScreen extends StatefulWidget {
  const AdminQuestionsListScreen({super.key});

  @override
  State<AdminQuestionsListScreen> createState() =>
      _AdminQuestionsListScreenState();
}

class _AdminQuestionsListScreenState extends State<AdminQuestionsListScreen> {
  String _filterCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'All Questions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                'all', 'privacy', 'passwords', 'cyberbullying',
                'social_media', 'phishing'
              ].map((cat) => GestureDetector(
                onTap: () => setState(() => _filterCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: _filterCategory == cat
                        ? const Color(0xFF00D4FF).withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _filterCategory == cat
                          ? const Color(0xFF00D4FF)
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: _filterCategory == cat
                          ? const Color(0xFF00D4FF)
                          : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),

          // Questions list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filterCategory == 'all'
                  ? FirebaseFirestore.instance
                  .collection('questions')
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection('questions')
                  .where('categoryId', isEqualTo: _filterCategory)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No questions found',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['categoryId']} › ${data['topicId']} · ${data['difficulty']}',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A2E),
                                title: const Text('Delete question?',
                                    style: TextStyle(color: Colors.white)),
                                content: const Text(
                                    'This cannot be undone.',
                                    style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('questions')
                                          .doc(docId)
                                          .delete();
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}