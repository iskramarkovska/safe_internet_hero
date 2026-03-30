import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_content_header.dart';
import '../../widgets/admin_content_ui.dart';
import '../../widgets/content_category_topic_section.dart';
import '../../widgets/content_details_section.dart';
import '../../widgets/content_type_selector.dart';
import '../../widgets/quick_add_topic_sheet.dart';
import 'category_topic_manager_screen.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _readTimeController = TextEditingController();

  final LearningService _service = LearningService();
  final TopicsService _topicsService = TopicsService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  bool _loading = true;
  bool _isSaving = false;
  ContentType _type = ContentType.article;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _thumbnailController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _topicsService.getCategories();

    String? selectedCategory = _categoryId;
    if (categories.isNotEmpty) {
      final exists = categories.any((c) => c.id == selectedCategory);
      selectedCategory = exists ? selectedCategory : categories.first.id;
    } else {
      selectedCategory = null;
    }

    setState(() {
      _categories = categories;
      _categoryId = selectedCategory;
    });

    if (selectedCategory != null) {
      await _loadTopics(selectedCategory);
    } else {
      setState(() {
        _topics = [];
        _topicId = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadTopics(String categoryId) async {
    final topics = await _topicsService.getTopicsByCategory(categoryId);

    String? selectedTopic = _topicId;
    if (topics.isNotEmpty) {
      final exists = topics.any((t) => t.id == selectedTopic);
      selectedTopic = exists ? selectedTopic : topics.first.id;
    } else {
      selectedTopic = null;
    }

    setState(() {
      _topics = topics;
      _topicId = selectedTopic;
      _loading = false;
    });
  }

  Future<void> _openManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryTopicManagerScreen()),
    );
    await _loadCategories();
  }

  Future<void> _showQuickAddTopicSheet() async {
    if (_categoryId == null) {
      _showSnack('Please select a category first', isError: true);
      return;
    }

    final category = _categories.firstWhere((c) => c.id == _categoryId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return QuickAddTopicSheet(
          categoryTitle: category.title,
          initialOrder: _topics.length + 1,
          onSave: (name, desc, isNew, isUpdated, order) async {
            final topic = TopicModel(
              id: FirebaseFirestore.instance.collection('topics').doc().id,
              categoryId: category.id,
              name: name,
              desc: desc,
              isNew: isNew,
              isUpdated: isUpdated,
              order: order,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await _topicsService.saveTopic(topic);
            if (!mounted) return;
            await _loadTopics(category.id);
            setState(() => _topicId = topic.id);
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) {
      _showSnack('Please select category and topic', isError: true);
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnack('Title and content are required', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final content = LearningContentModel(
        id: '',
        categoryId: _categoryId!,
        topicId: _topicId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        content: _contentController.text.trim(),
        thumbnailUrl: _thumbnailController.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeController.text.trim()) ?? 0,
        createdAt: DateTime.now(),
      );

      await _service.saveContent(content);

      _titleController.clear();
      _descriptionController.clear();
      _contentController.clear();
      _thumbnailController.clear();
      _readTimeController.clear();

      setState(() => _isSaving = false);
      _showSnack('Content saved!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnack('Error: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AdminContentUi.red : AdminContentUi.tealDark,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminContentUi.cream,
      body: SafeArea(
        child: Column(
          children: [
            AdminContentHeader(
              onBack: () => Navigator.pop(context),
              onManage: _openManager,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        ContentCategoryTopicSection(
                          categories: _categories,
                          topics: _topics,
                          selectedCategoryId: _categoryId,
                          selectedTopicId: _topicId,
                          onAddTopic: _showQuickAddTopicSheet,
                          onTopicChanged: (val) =>
                              setState(() => _topicId = val),
                          onCategoryChanged: (val) async {
                            if (val == null) return;
                            setState(() {
                              _categoryId = val;
                              _topicId = null;
                              _topics = [];
                              _loading = true;
                            });
                            await _loadTopics(val);
                          },
                        ),
                        const SizedBox(height: 16),
                        ContentTypeSelector(
                          selectedType: _type,
                          onChanged: (type) => setState(() => _type = type),
                        ),
                        const SizedBox(height: 16),
                        ContentDetailsSection(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          contentController: _contentController,
                          thumbnailController: _thumbnailController,
                          readTimeController: _readTimeController,
                          type: _type,
                        ),
                        const SizedBox(height: 20),
                        AdminPrimaryButton(
                          label: _isSaving ? 'Saving...' : 'Save Content',
                          onTap: _isSaving ? () {} : _save,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}