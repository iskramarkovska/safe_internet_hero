import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_content_ui.dart';
import '../../widgets/content_category_topic_section.dart';
import '../../widgets/content_type_selector.dart';
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
      MaterialPageRoute(
        builder: (_) => const CategoryTopicManagerScreen(),
      ),
    );
    await _loadCategories();
  }

  Future<void> _showQuickAddTopicSheet() async {
    if (_categoryId == null) {
      _showSnack('Please select a category first', isError: true);
      return;
    }

    final category = _categories.firstWhere((c) => c.id == _categoryId);
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isNew = true;
        bool isUpdated = false;
        int order = _topics.length + 1;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminContentUi.cream,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Add Topic to ${category.title}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const AdminSectionLabel('Topic Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration:
                      AdminContentUi.inputDecoration('Enter topic name'),
                    ),
                    const SizedBox(height: 16),
                    const AdminSectionLabel('Description'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration:
                      AdminContentUi.inputDecoration('Short description'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AdminToggleCard(
                            label: 'New',
                            value: isNew,
                            color: const Color(0xFFF45B8C),
                            onTap: () =>
                                setModalState(() => isNew = !isNew),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminToggleCard(
                            label: 'Updated',
                            value: isUpdated,
                            color: const Color(0xFFFFA726),
                            onTap: () => setModalState(
                                  () => isUpdated = !isUpdated,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const AdminSectionLabel('Order'),
                    const SizedBox(height: 8),
                    AdminOrderStepper(
                      value: order,
                      onChanged: (value) =>
                          setModalState(() => order = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: AdminSecondaryButton(
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminPrimaryButton(
                            label: 'Save Topic',
                            onTap: () async {
                              final name = nameController.text.trim();
                              final desc = descController.text.trim();
                              if (name.isEmpty || desc.isEmpty) return;

                              final topic = TopicModel(
                                id: FirebaseFirestore.instance
                                    .collection('topics')
                                    .doc()
                                    .id,
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
                              Navigator.pop(context);
                              await _loadTopics(category.id);
                              setState(() => _topicId = topic.id);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
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
        backgroundColor:
        isError ? AdminContentUi.red : AdminContentUi.tealDark,
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
            Container(
              decoration: const BoxDecoration(
                color: AdminContentUi.teal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFF0C2),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AdminContentUi.tealDark,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Learning Content',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) async {
                      if (value == 'manage') {
                        await _openManager();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'manage',
                        child: Text('Manage Categories & Topics'),
                      ),
                    ],
                    child: Container(
                      decoration: BoxDecoration(
                        color: AdminContentUi.gold,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AdminContentUi.goldDark,
                          width: 2,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF5A7A6A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  AdminSectionCard(
                    title: 'Where does this content belong?',
                    child: Column(
                      children: [
                        const AdminSectionLabel('Category'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration: AdminContentUi.inputDecoration(
                            'Select category',
                          ),
                          items: _categories
                              .map(
                                (cat) => DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.title),
                            ),
                          )
                              .toList(),
                          onChanged: (val) async {
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
                        Row(
                          children: [
                            const Expanded(
                              child: AdminStaticLabel(text: 'Topic'),
                            ),
                            TextButton.icon(
                              onPressed: _showQuickAddTopicSheet,
                              icon:
                              const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Topic'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _topicId,
                          decoration: AdminContentUi.inputDecoration(
                            'Select topic',
                          ),
                          items: _topics
                              .map(
                                (topic) => DropdownMenuItem(
                              value: topic.id,
                              child: Text(topic.name),
                            ),
                          )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _topicId = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ContentCategoryTopicSection(
                    categories: _categories,
                    topics: _topics,
                    selectedCategoryId: _categoryId,
                    selectedTopicId: _topicId,
                    onAddTopic: _showQuickAddTopicSheet,
                    onTopicChanged: (val) => setState(() => _topicId = val),
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

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AdminContentUi.teal.withOpacity(0.15)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AdminContentUi.teal
                : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? AdminContentUi.tealDark
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}