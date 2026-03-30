import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/enums.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() => _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState extends State<ManageQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _AddQuestionForm(),
                  _QuestionsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TabController tabController;
  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.teal,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text('Manage Questions', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 48),
          ]),
        ),
        TabBar(
          controller: tabController,
          indicatorColor: AdminColors.yellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [Tab(text: 'Add Question'), Tab(text: 'All Questions')],
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADD / EDIT FORM
// ─────────────────────────────────────────────────────────────

class _AddQuestionForm extends StatefulWidget {
  const _AddQuestionForm();

  @override
  State<_AddQuestionForm> createState() => _AddQuestionFormState();
}

class _AddQuestionFormState extends State<_AddQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _opt0Ctrl = TextEditingController();
  final _opt1Ctrl = TextEditingController();
  final _opt2Ctrl = TextEditingController();
  final _opt3Ctrl = TextEditingController();

  final TopicsService _topicsService = TopicsService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  bool _loading = true;
  bool _saving = false;
  QuestionType _type = QuestionType.multipleChoice;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  int _correctIndex = 0;
  QuestionModel? _editing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose(); _explanationCtrl.dispose();
    _opt0Ctrl.dispose(); _opt1Ctrl.dispose();
    _opt2Ctrl.dispose(); _opt3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await _topicsService.getCategories();
    setState(() { _categories = cats; _categoryId = cats.isNotEmpty ? cats.first.id : null; });
    if (_categoryId != null) await _loadTopics(_categoryId!);
    else setState(() => _loading = false);
  }

  Future<void> _loadTopics(String catId) async {
    setState(() => _loading = true);
    final topics = await _topicsService.getTopicsByCategory(catId);
    setState(() { _topics = topics; _topicId = topics.isNotEmpty ? topics.first.id : null; _loading = false; });
  }

  void _clearForm() {
    _textCtrl.clear(); _explanationCtrl.clear();
    _opt0Ctrl.clear(); _opt1Ctrl.clear(); _opt2Ctrl.clear(); _opt3Ctrl.clear();
    setState(() { _editing = null; _correctIndex = 0; _type = QuestionType.multipleChoice; _difficulty = DifficultyLevel.beginner; });
  }

  int get _points => _difficulty == DifficultyLevel.beginner ? 10 : _difficulty == DifficultyLevel.intermediate ? 20 : 30;

  List<String> get _options => _type == QuestionType.trueFalse
      ? ['True', 'False']
      : [_opt0Ctrl.text.trim(), _opt1Ctrl.text.trim(), _opt2Ctrl.text.trim(), _opt3Ctrl.text.trim()];

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) { _snack('Select category and topic', isError: true); return; }
    if (!_formKey.currentState!.validate()) return;
    if (_type == QuestionType.multipleChoice) {
      if ([_opt0Ctrl, _opt1Ctrl, _opt2Ctrl, _opt3Ctrl].any((c) => c.text.trim().isEmpty)) {
        _snack('Fill in all 4 options', isError: true); return;
      }
    }
    setState(() => _saving = true);
    try {
      await QuestionService().seedQuestions([QuestionModel(
        id: _editing?.id ?? '',
        categoryId: _categoryId!, topicId: _topicId!,
        text: _textCtrl.text.trim(), type: _type, options: _options,
        correctIndex: _correctIndex, explanation: _explanationCtrl.text.trim(),
        difficulty: _difficulty, points: _points,
      )]);
      _clearForm();
      setState(() => _saving = false);
      _snack('Question saved!');
    } catch (e) {
      setState(() => _saving = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AdminColors.red : AdminColors.darkTeal));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AdminColors.teal));

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_editing != null) AdminEditBanner(title: _editing!.text, onClear: _clearForm),

          AdminCard(title: 'Where does this question belong?', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminLabel('Category'), const SizedBox(height: 8),
              AdminDropdown<String>(value: _categoryId, hint: 'Select category',
                  items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))).toList(),
                  onChanged: (val) async { if (val == null) return; setState(() { _categoryId = val; _topicId = null; }); await _loadTopics(val); }),
              const SizedBox(height: 14),
              const AdminLabel('Topic'), const SizedBox(height: 8),
              AdminDropdown<String>(value: _topicId, hint: 'Select topic',
                  items: _topics.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (val) => setState(() => _topicId = val)),
            ],
          )),
          const SizedBox(height: 14),

          AdminCard(title: 'Question setup', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminLabel('Type'), const SizedBox(height: 8),
              Row(children: [
                Expanded(child: AdminSelectTile(label: 'Multiple Choice', selected: _type == QuestionType.multipleChoice,
                    onTap: () => setState(() { _type = QuestionType.multipleChoice; _correctIndex = 0; }))),
                const SizedBox(width: 10),
                Expanded(child: AdminSelectTile(label: 'True / False', selected: _type == QuestionType.trueFalse,
                    onTap: () => setState(() { _type = QuestionType.trueFalse; _correctIndex = 0; }))),
              ]),
              const SizedBox(height: 14),
              const AdminLabel('Difficulty'), const SizedBox(height: 8),
              Row(children: [
                Expanded(child: AdminDifficultyTile(label: 'Beginner', color: Colors.green,
                    selected: _difficulty == DifficultyLevel.beginner, onTap: () => setState(() => _difficulty = DifficultyLevel.beginner))),
                const SizedBox(width: 8),
                Expanded(child: AdminDifficultyTile(label: 'Intermediate', color: Colors.orange,
                    selected: _difficulty == DifficultyLevel.intermediate, onTap: () => setState(() => _difficulty = DifficultyLevel.intermediate))),
                const SizedBox(width: 8),
                Expanded(child: AdminDifficultyTile(label: 'Advanced', color: AdminColors.red,
                    selected: _difficulty == DifficultyLevel.advanced, onTap: () => setState(() => _difficulty = DifficultyLevel.advanced))),
              ]),
            ],
          )),
          const SizedBox(height: 14),

          AdminCard(title: 'Question', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _textCtrl, maxLines: 3,
                  decoration: AdminField.decoration('Type your question here...'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 14),
              if (_type == QuestionType.multipleChoice) ...[
                const AdminLabel('Options — tap letter to mark correct'), const SizedBox(height: 8),
                AdminOptionField(controller: _opt0Ctrl, letter: 'A', index: 0, correctIndex: _correctIndex, onTap: () => setState(() => _correctIndex = 0)),
                const SizedBox(height: 8),
                AdminOptionField(controller: _opt1Ctrl, letter: 'B', index: 1, correctIndex: _correctIndex, onTap: () => setState(() => _correctIndex = 1)),
                const SizedBox(height: 8),
                AdminOptionField(controller: _opt2Ctrl, letter: 'C', index: 2, correctIndex: _correctIndex, onTap: () => setState(() => _correctIndex = 2)),
                const SizedBox(height: 8),
                AdminOptionField(controller: _opt3Ctrl, letter: 'D', index: 3, correctIndex: _correctIndex, onTap: () => setState(() => _correctIndex = 3)),
              ],
              if (_type == QuestionType.trueFalse) ...[
                const AdminLabel('Correct answer'), const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: AdminSelectTile(label: 'True', selected: _correctIndex == 0, color: Colors.green, onTap: () => setState(() => _correctIndex = 0))),
                  const SizedBox(width: 12),
                  Expanded(child: AdminSelectTile(label: 'False', selected: _correctIndex == 1, color: Colors.green, onTap: () => setState(() => _correctIndex = 1))),
                ]),
              ],
              const SizedBox(height: 14),
              const AdminLabel('Explanation'), const SizedBox(height: 8),
              TextFormField(controller: _explanationCtrl, maxLines: 3,
                  decoration: AdminField.decoration('Why is this the correct answer?'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            ],
          )),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Text('This question awards $_points points', textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          AdminPrimaryButton(label: _saving ? 'Saving...' : 'Save Question', onTap: _saving ? () {} : _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUESTIONS LIST
// ─────────────────────────────────────────────────────────────

class _QuestionsList extends StatelessWidget {
  const _QuestionsList();

  Future<void> _delete(BuildContext context, QuestionModel q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Question'),
        content: Text('"${q.text}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AdminColors.red))),
        ],
      ),
    );
    if (ok == true) {
      await QuestionService().deleteQuestion(q.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted'), backgroundColor: AdminColors.darkTeal));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuestionModel>>(
      stream: QuestionService().watchAllQuestions(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AdminColors.teal));
        final items = snap.data!;
        if (items.isEmpty) return const AdminEmptyState(
            icon: Icons.quiz_rounded, title: 'No questions yet', subtitle: 'Add some from the "Add Question" tab');

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final q = items[i];
            final diffColor = q.difficulty == DifficultyLevel.beginner ? Colors.green
                : q.difficulty == DifficultyLevel.intermediate ? Colors.orange : AdminColors.red;
            final diffLabel = q.difficulty == DifficultyLevel.beginner ? 'Beginner'
                : q.difficulty == DifficultyLevel.intermediate ? 'Intermediate' : 'Advanced';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    AdminBadge(text: diffLabel, color: diffColor),
                    AdminBadge(text: q.type == QuestionType.trueFalse ? 'T/F' : 'MCQ', color: AdminColors.teal),
                    const SizedBox(width: 4),
                    Text('${q.points} pts', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                  ]),
                  const SizedBox(height: 6),
                  Text(q.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text('✓ ${q.options.isNotEmpty ? q.options[q.correctIndex] : ""}',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ])),
                IconButton(icon: const Icon(Icons.delete_rounded, color: AdminColors.red, size: 20),
                    onPressed: () => _delete(context, q)),
              ]),
            );
          },
        );
      },
    );
  }
}