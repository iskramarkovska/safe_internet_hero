import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/enums.dart';
import '../../models/learning_content_model.dart';
import '../../models/question_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/questions_service.dart';
import '../../services/topics_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const teal = Color(0xFF2BBFAA);
  static const yellow = Color(0xFFE8C84A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: teal,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Admin Panel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: yellow,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Questions'),
                      Tab(text: 'Learning Content'),
                      Tab(text: 'Categories & Topics'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _QuestionsTab(),
                  _ContentTab(),
                  _ManageTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionsTab extends StatefulWidget {
  const _QuestionsTab();

  @override
  State<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<_QuestionsTab> {
  static const teal = Color(0xFF2BBFAA);
  static const red = Color(0xFFE8524A);

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _explanationCtrl.dispose();
    _opt0Ctrl.dispose();
    _opt1Ctrl.dispose();
    _opt2Ctrl.dispose();
    _opt3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cats = await _topicsService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _categoryId = cats.isNotEmpty ? cats.first.id : null;
    });
    if (_categoryId != null) {
      await _loadTopics(_categoryId!);
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final topics = await _topicsService.getTopicsByCategory(catId);
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _topicId = topics.isNotEmpty ? topics.first.id : null;
      _loading = false;
    });
  }

  int get _points => _difficulty == DifficultyLevel.beginner
      ? 10
      : _difficulty == DifficultyLevel.intermediate
      ? 20
      : 30;

  List<String> get _options => _type == QuestionType.trueFalse
      ? ['True', 'False']
      : [
    _opt0Ctrl.text.trim(),
    _opt1Ctrl.text.trim(),
    _opt2Ctrl.text.trim(),
    _opt3Ctrl.text.trim(),
  ];

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) {
      _snack('Select category and topic', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_type == QuestionType.multipleChoice) {
      if ([_opt0Ctrl, _opt1Ctrl, _opt2Ctrl, _opt3Ctrl]
          .any((c) => c.text.trim().isEmpty)) {
        _snack('Fill in all 4 options', isError: true);
        return;
      }
    }

    setState(() => _saving = true);

    try {
      await QuestionService().seedQuestions([
        QuestionModel(
          id: '',
          categoryId: _categoryId!,
          topicId: _topicId!,
          text: _textCtrl.text.trim(),
          type: _type,
          options: _options,
          correctIndex: _correctIndex,
          explanation: _explanationCtrl.text.trim(),
          difficulty: _difficulty,
          points: _points,
        ),
      ]);

      _textCtrl.clear();
      _explanationCtrl.clear();
      _opt0Ctrl.clear();
      _opt1Ctrl.clear();
      _opt2Ctrl.clear();
      _opt3Ctrl.clear();

      if (!mounted) return;
      setState(() {
        _correctIndex = 0;
        _saving = false;
      });
      _snack('Question saved!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? red : const Color(0xFF1A9E8F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: teal));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Card(
            title: 'Where does this question belong?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Category'),
                const SizedBox(height: 8),
                _Dropdown<String>(
                  value: _categoryId,
                  hint: 'Select category',
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.title),
                    ),
                  )
                      .toList(),
                  onChanged: (val) async {
                    if (val == null) return;
                    setState(() {
                      _categoryId = val;
                      _topicId = null;
                    });
                    await _loadTopics(val);
                  },
                ),
                const SizedBox(height: 14),
                const _Label('Topic'),
                const SizedBox(height: 8),
                _Dropdown<String>(
                  value: _topicId,
                  hint: 'Select topic',
                  items: _topics
                      .map(
                        (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    ),
                  )
                      .toList(),
                  onChanged: (val) => setState(() => _topicId = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Question setup',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Type'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceTile(
                        label: 'Multiple Choice',
                        selected: _type == QuestionType.multipleChoice,
                        onTap: () => setState(() {
                          _type = QuestionType.multipleChoice;
                          _correctIndex = 0;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChoiceTile(
                        label: 'True / False',
                        selected: _type == QuestionType.trueFalse,
                        onTap: () => setState(() {
                          _type = QuestionType.trueFalse;
                          _correctIndex = 0;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _Label('Difficulty'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DiffTile(
                        label: 'Beginner',
                        color: Colors.green,
                        selected: _difficulty == DifficultyLevel.beginner,
                        onTap: () => setState(
                              () => _difficulty = DifficultyLevel.beginner,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DiffTile(
                        label: 'Intermediate',
                        color: Colors.orange,
                        selected:
                        _difficulty == DifficultyLevel.intermediate,
                        onTap: () => setState(
                              () => _difficulty = DifficultyLevel.intermediate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DiffTile(
                        label: 'Advanced',
                        color: red,
                        selected: _difficulty == DifficultyLevel.advanced,
                        onTap: () => setState(
                              () => _difficulty = DifficultyLevel.advanced,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Question',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textCtrl,
                  maxLines: 3,
                  decoration: _inputDec('Type your question here...'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                if (_type == QuestionType.multipleChoice) ...[
                  const _Label('Options — tap letter to mark correct'),
                  const SizedBox(height: 8),
                  _OptionField(
                    ctrl: _opt0Ctrl,
                    letter: 'A',
                    index: 0,
                    correct: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 0),
                  ),
                  const SizedBox(height: 8),
                  _OptionField(
                    ctrl: _opt1Ctrl,
                    letter: 'B',
                    index: 1,
                    correct: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 1),
                  ),
                  const SizedBox(height: 8),
                  _OptionField(
                    ctrl: _opt2Ctrl,
                    letter: 'C',
                    index: 2,
                    correct: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 2),
                  ),
                  const SizedBox(height: 8),
                  _OptionField(
                    ctrl: _opt3Ctrl,
                    letter: 'D',
                    index: 3,
                    correct: _correctIndex,
                    onTap: () => setState(() => _correctIndex = 3),
                  ),
                ],
                if (_type == QuestionType.trueFalse) ...[
                  const _Label('Correct answer'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceTile(
                          label: 'True',
                          selected: _correctIndex == 0,
                          color: Colors.green,
                          onTap: () => setState(() => _correctIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChoiceTile(
                          label: 'False',
                          selected: _correctIndex == 1,
                          color: Colors.green,
                          onTap: () => setState(() => _correctIndex = 1),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const _Label('Explanation'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _explanationCtrl,
                  maxLines: 3,
                  decoration: _inputDec('Why is this the correct answer?'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              'This question awards $_points points',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TealBtn(
            label: _saving ? 'Saving...' : 'Save Question',
            onTap: _saving ? () {} : _save,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: teal, width: 2),
    ),
  );
}

class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab>
    with SingleTickerProviderStateMixin {
  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);

  late TabController _subTabController;
  LearningContentModel? _selectedContent;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _startEditing(LearningContentModel item) {
    setState(() {
      _selectedContent = item;
    });
    _subTabController.animateTo(0);
  }

  void _clearEditing() {
    if (!mounted) return;
    setState(() {
      _selectedContent = null;
    });
  }

  void _handleSaved() {
    if (!mounted) return;
    setState(() {
      _selectedContent = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF0FAF8),
          child: TabBar(
            controller: _subTabController,
            indicatorColor: teal,
            labelColor: darkTeal,
            unselectedLabelColor: const Color(0xFF9CA3AF),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Content Form'),
              Tab(text: 'All Content'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _ContentForm(
                content: _selectedContent,
                onCancelEdit: _clearEditing,
                onSaved: _handleSaved,
              ),
              _ContentList(
                onEdit: _startEditing,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentForm extends StatefulWidget {
  final LearningContentModel? content;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaved;

  const _ContentForm({
    required this.content,
    required this.onCancelEdit,
    required this.onSaved,
  });

  @override
  State<_ContentForm> createState() => _ContentFormState();
}

class _ContentFormState extends State<_ContentForm> {
  static const teal = Color(0xFF2BBFAA);
  static const red = Color(0xFFE8524A);

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _thumbCtrl = TextEditingController();
  final _readTimeCtrl = TextEditingController();

  final TopicsService _topicsService = TopicsService();
  final LearningService _learningService = LearningService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];

  String? _categoryId;
  String? _topicId;

  bool _loading = true;
  bool _saving = false;

  ContentType _type = ContentType.article;
  String? _loadedContentId;

  bool get _isEditing => widget.content != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _ContentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newId = widget.content?.id;
    if (newId != _loadedContentId) {
      _applyIncomingContent();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _thumbCtrl.dispose();
    _readTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadCategories();
    await _applyIncomingContent(initial: true);
  }

  Future<void> _loadCategories() async {
    final cats = await _topicsService.getCategories();
    if (!mounted) return;

    setState(() {
      _categories = cats;
      if (_categoryId == null && cats.isNotEmpty) {
        _categoryId = cats.first.id;
      }
    });

    if (_categoryId != null) {
      await _loadTopics(_categoryId!, preserveTopic: true);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadTopics(String catId, {bool preserveTopic = false}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final topics = await _topicsService.getTopicsByCategory(catId);

    if (!mounted) return;
    setState(() {
      _topics = topics;
      if (!preserveTopic ||
          _topicId == null ||
          !_topics.any((t) => t.id == _topicId)) {
        _topicId = topics.isNotEmpty ? topics.first.id : null;
      }
      _loading = false;
    });
  }

  Future<void> _applyIncomingContent({bool initial = false}) async {
    final item = widget.content;

    if (item == null) {
      _loadedContentId = null;
      _titleCtrl.clear();
      _descCtrl.clear();
      _contentCtrl.clear();
      _thumbCtrl.clear();
      _readTimeCtrl.clear();

      if (!mounted) return;
      setState(() {
        _type = ContentType.article;
        _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
        _topicId = null;
        _topics = [];
        _loading = true;
      });

      if (_categoryId != null) {
        await _loadTopics(_categoryId!, preserveTopic: false);
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
      return;
    }

    _loadedContentId = item.id;

    _titleCtrl.text = item.title;
    _descCtrl.text = item.description;
    _contentCtrl.text = item.content;
    _thumbCtrl.text = item.thumbnailUrl;
    _readTimeCtrl.text =
    item.readTimeMinutes > 0 ? item.readTimeMinutes.toString() : '';

    if (!mounted) return;
    setState(() {
      _loading = true;
      _type = item.type;
      _categoryId = item.categoryId;
      _topicId = null; 
      _topics = [];
    });

    await _loadTopics(item.categoryId, preserveTopic: false);

    if (!mounted) return;
    setState(() {
      final topicExists = _topics.any((t) => t.id == item.topicId);
      _topicId = topicExists ? item.topicId : null;
      _loading = false;
    });
  }

  void _resetFormToCreateMode() async {
    widget.onCancelEdit();
  }

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) {
      _snack('Select category and topic', isError: true);
      return;
    }

    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      _snack('Title and content are required', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      final existing = widget.content;

      final model = LearningContentModel(
        id: existing?.id ?? '',
        categoryId: _categoryId!,
        topicId: _topicId!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        type: _type,
        content: _contentCtrl.text.trim(),
        thumbnailUrl: _thumbCtrl.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeCtrl.text.trim()) ?? 0,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _learningService.updateContent(model);
      } else {
        await _learningService.saveContent(model);
      }

      if (!mounted) return;
      setState(() => _saving = false);

      widget.onSaved();
      _snack(_isEditing ? 'Content updated!' : 'Content saved!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? red : const Color(0xFF1A9E8F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: teal));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_isEditing)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB300)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFFFFB300),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Editing: ${widget.content!.title}',
                    style: const TextStyle(
                      color: Color(0xFF8A6B12),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _resetFormToCreateMode,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8A6B12),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        _Card(
          title: 'Where does this content belong?',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Category'),
              const SizedBox(height: 8),
              _Dropdown<String>(
                value: _categoryId,
                hint: 'Select category',
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.title),
                  ),
                )
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() {
                    _categoryId = val;
                    _topicId = null;
                  });
                  await _loadTopics(val, preserveTopic: false);
                },
              ),
              const SizedBox(height: 14),
              const _Label('Topic'),
              const SizedBox(height: 8),
              _Dropdown<String>(
                value: _topicId,
                hint: 'Select topic',
                items: _topics
                    .map(
                      (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name),
                  ),
                )
                    .toList(),
                onChanged: (val) => setState(() => _topicId = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Content type',
          child: Row(
            children: [
              Expanded(
                child: _TypeBtn(
                  label: 'Article',
                  icon: Icons.article_rounded,
                  selected: _type == ContentType.article,
                  onTap: () => setState(() => _type = ContentType.article),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeBtn(
                  label: 'Video',
                  icon: Icons.play_circle_rounded,
                  selected: _type == ContentType.video,
                  onTap: () => setState(() => _type = ContentType.video),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeBtn(
                  label: 'Image',
                  icon: Icons.image_rounded,
                  selected: _type == ContentType.infographic,
                  onTap: () => setState(() => _type = ContentType.infographic),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          title: 'Content details',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Title'),
              const SizedBox(height: 8),
              _Field(controller: _titleCtrl, hint: 'Content title'),
              const SizedBox(height: 14),
              const _Label('Description'),
              const SizedBox(height: 8),
              _Field(
                controller: _descCtrl,
                hint: 'Short description shown on card',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _Label(
                _type == ContentType.video
                    ? 'YouTube Video ID'
                    : _type == ContentType.infographic
                    ? 'Image URL'
                    : 'Article text',
              ),
              const SizedBox(height: 8),
              _Field(
                controller: _contentCtrl,
                maxLines: _type == ContentType.article ? 8 : 1,
                hint: _type == ContentType.video
                    ? 'e.g. dQw4w9WgXcQ'
                    : _type == ContentType.infographic
                    ? 'https://example.com/image.jpg'
                    : 'Write your article here...',
              ),
              const SizedBox(height: 14),
              const _Label('Thumbnail URL (optional)'),
              const SizedBox(height: 8),
              _Field(
                controller: _thumbCtrl,
                hint: 'https://example.com/thumbnail.jpg',
              ),
              if (_type == ContentType.article) ...[
                const SizedBox(height: 14),
                const _Label('Read time (minutes)'),
                const SizedBox(height: 8),
                _Field(controller: _readTimeCtrl, hint: 'e.g. 3'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TealBtn(
          label: _saving
              ? 'Saving...'
              : _isEditing
              ? 'Update Content'
              : 'Save Content',
          onTap: _saving ? () {} : _save,
        ),
      ],
    );
  }
}

class _ContentList extends StatelessWidget {
  final ValueChanged<LearningContentModel> onEdit;

  const _ContentList({
    required this.onEdit,
  });

  static const teal = Color(0xFF2BBFAA);
  static const red = Color(0xFFE8524A);

  Future<void> _delete(BuildContext context, LearningContentModel item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Content'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await LearningService().deleteContent(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted'),
            backgroundColor: Color(0xFF1A9E8F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LearningContentModel>>(
      stream: LearningService().getAllContent(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: teal),
          );
        }

        final items = snap.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.library_books_rounded,
                  color: Color(0xFFD1D5DB),
                  size: 56,
                ),
                SizedBox(height: 12),
                Text(
                  'No content yet',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Create content from the form tab',
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isVideo = item.type == ContentType.video;
            final isImage = item.type == ContentType.infographic;
            final typeColor =
            isVideo ? red : isImage ? const Color(0xFFFFB300) : teal;
            final typeLabel = isVideo ? 'VIDEO' : isImage ? 'IMAGE' : 'ARTICLE';
            final typeIcon = isVideo
                ? Icons.play_circle_rounded
                : isImage
                ? Icons.image_rounded
                : Icons.article_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.categoryId,
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: teal,
                      size: 20,
                    ),
                    onPressed: () => onEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: red,
                      size: 20,
                    ),
                    onPressed: () => _delete(context, item),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ManageTab extends StatefulWidget {
  const _ManageTab();

  @override
  State<_ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<_ManageTab> {
  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);
  static const red = Color(0xFFE8524A);
  static const yellow = Color(0xFFE8C84A);
  static const yellowDark = Color(0xFFC8A830);

  final TopicsService _service = TopicsService();
  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _selectedCatId;
  bool _loadingCats = true;
  bool _loadingTopics = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => _loadingCats = true);
    final cats = await _service.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _selectedCatId = cats.isNotEmpty ? cats.first.id : null;
      _loadingCats = false;
    });
    if (_selectedCatId != null) {
      await _loadTopics(_selectedCatId!);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (!mounted) return;
    setState(() => _loadingTopics = true);
    final topics = await _service.getTopicsByCategory(catId);
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _loadingTopics = false;
    });
  }

  Future<void> _showCategorySheet({CategoryModel? cat}) async {
    final titleCtrl = TextEditingController(text: cat?.title ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(
        title: cat == null ? 'Add Category' : 'Edit Category',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Category Name'),
            const SizedBox(height: 8),
            _Field(controller: titleCtrl, hint: 'e.g. Privacy'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OutBtn(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TealBtn(
                    label: cat == null ? 'Save' : 'Update',
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      await _service.saveCategory(
                        CategoryModel(
                          id: cat?.id ??
                              FirebaseFirestore.instance
                                  .collection('categories')
                                  .doc()
                                  .id,
                          title: title,
                          order: cat?.order ?? (_categories.length + 1),
                        ),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      await _loadCategories();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTopicSheet({
    required String catId,
    TopicModel? topic,
  }) async {
    final nameCtrl = TextEditingController(text: topic?.name ?? '');
    final descCtrl = TextEditingController(text: topic?.desc ?? '');
    var isNew = topic == null;
    var isUpdated = topic?.isUpdated ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => _BottomSheet(
          title: topic == null ? 'Add Topic' : 'Edit Topic',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Topic Name'),
              const SizedBox(height: 8),
              _Field(controller: nameCtrl, hint: 'e.g. Strong Passwords'),
              const SizedBox(height: 14),
              const _Label('Description'),
              const SizedBox(height: 8),
              _Field(
                controller: descCtrl,
                hint: 'Short description',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              if (topic == null)
                _Toggle(
                  label: 'Mark as New',
                  value: isNew,
                  color: const Color(0xFFF45B8C),
                  onChanged: (v) => setS(() => isNew = v),
                ),
              if (topic != null)
                _Toggle(
                  label: 'Mark as Updated',
                  value: isUpdated,
                  color: const Color(0xFFFFA726),
                  onChanged: (v) => setS(() => isUpdated = v),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _OutBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TealBtn(
                      label: topic == null ? 'Save' : 'Update',
                      onTap: () async {
                        final name = nameCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        if (name.isEmpty || desc.isEmpty) return;
                        await _service.saveTopic(
                          TopicModel(
                            id: topic?.id ??
                                FirebaseFirestore.instance
                                    .collection('topics')
                                    .doc()
                                    .id,
                            categoryId: catId,
                            name: name,
                            desc: desc,
                            isNew: topic == null ? isNew : false,
                            isUpdated: topic != null ? isUpdated : false,
                            order: topic?.order ?? (_topics.length + 1),
                            createdAt: topic?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          ),
                        );
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        await _loadTopics(catId);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCat(CategoryModel cat) async {
    final ok = await _confirm(
      'Delete "${cat.title}"?',
      'All topics and questions will be deleted.',
    );
    if (!ok) return;
    final db = FirebaseFirestore.instance;
    final topics = await _service.getTopicsByCategory(cat.id);
    for (final t in topics) {
      for (final col in ['questions', 'learning_content']) {
        final snap = await db.collection(col).where('topicId', isEqualTo: t.id).get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      }
      await _service.deleteTopic(t.id);
    }
    await _service.deleteCategory(cat.id);
    await _loadCategories();
  }

  Future<void> _deleteTopic(TopicModel topic) async {
    final ok = await _confirm(
      'Delete "${topic.name}"?',
      'Related questions will also be deleted.',
    );
    if (!ok) return;
    final db = FirebaseFirestore.instance;
    for (final col in ['questions', 'learning_content']) {
      final snap = await db.collection(col).where('topicId', isEqualTo: topic.id).get();
      for (final d in snap.docs) {
        await d.reference.delete();
      }
    }
    await _service.deleteTopic(topic.id);
    await _loadTopics(topic.categoryId);
  }

  Future<bool> _confirm(String title, String msg) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final selCat = _categories
        .cast<CategoryModel?>()
        .firstWhere((c) => c?.id == _selectedCatId, orElse: () => null);

    if (_loadingCats) {
      return const Center(child: CircularProgressIndicator(color: teal));
    }

    return Row(
      children: [
        Container(
          width: 200,
          margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: yellowDark),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF5A7A6A),
                          size: 16,
                        ),
                      ),
                      onPressed: _showCategorySheet,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _categories.isEmpty
                    ? const Center(
                  child: Text(
                    'No categories',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final sel = cat.id == _selectedCatId;

                    return GestureDetector(
                      onTap: () async {
                        setState(() => _selectedCatId = cat.id);
                        await _loadTopics(cat.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? teal.withOpacity(0.1)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? teal : const Color(0xFFE5E7EB),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: sel
                                      ? darkTeal
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showCategorySheet(cat: cat),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: teal,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _deleteCat(cat),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: red,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(6, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selCat == null ? 'Topics' : selCat.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (_selectedCatId != null)
                        TextButton.icon(
                          onPressed: () =>
                              _showTopicSheet(catId: _selectedCatId!),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: teal,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _selectedCatId == null
                      ? const Center(
                    child: Text(
                      'Select a category',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  )
                      : _loadingTopics
                      ? const Center(
                    child: CircularProgressIndicator(color: teal),
                  )
                      : _topics.isEmpty
                      ? const Center(
                    child: Text(
                      'No topics yet',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _topics.length,
                    itemBuilder: (_, i) {
                      final topic = _topics[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          topic.name,
                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.bold,
                                            fontSize: 13,
                                            color:
                                            Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      if (topic.isNew)
                                        _MiniTag(
                                          text: 'NEW',
                                          color: const Color(
                                            0xFFF45B8C,
                                          ),
                                        ),
                                      if (topic.isUpdated)
                                        _MiniTag(
                                          text: 'UPD',
                                          color: const Color(
                                            0xFFFFA726,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    topic.desc,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: teal,
                                size: 16,
                              ),
                              onPressed: () => _showTopicSheet(
                                catId: topic.categoryId,
                                topic: topic,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: red,
                                size: 16,
                              ),
                              onPressed: () =>
                                  _deleteTopic(topic),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheet({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAF7),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
        fontSize: 13,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2BBFAA), width: 2),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hint;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final matches = items.where((item) => item.value == value).length;
    final safeValue = matches == 1 ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2BBFAA), width: 2),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? color : const Color(0xFFE5E7EB),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: value ? color : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: value ? color : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2BBFAA).withOpacity(0.12)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
            selected ? const Color(0xFF2BBFAA) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF2BBFAA)
                  : const Color(0xFF9CA3AF),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1A9E8F)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2BBFAA);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? c : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DiffTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DiffTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? color : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  final TextEditingController ctrl;
  final String letter;
  final int index;
  final int correct;
  final VoidCallback onTap;

  const _OptionField({
    required this.ctrl,
    required this.letter,
    required this.index,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = correct == index;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCorrect ? Colors.green : const Color(0xFFE5E7EB),
            width: isCorrect ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 50,
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withOpacity(0.12)
                    : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  isCorrect ? '✓' : letter,
                  style: TextStyle(
                    color:
                    isCorrect ? Colors.green : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Option $letter',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TealBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TealBtn({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF2BBFAA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A9E8F), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF1A9E8F),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutBtn({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}