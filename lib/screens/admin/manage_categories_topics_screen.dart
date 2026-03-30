import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/topic_model.dart';
import '../../services/topics_service.dart';

class CategoryTopicManagerScreen extends StatefulWidget {
  const CategoryTopicManagerScreen({super.key});

  @override
  State<CategoryTopicManagerScreen> createState() => _CategoryTopicManagerScreenState();
}

class _CategoryTopicManagerScreenState extends State<CategoryTopicManagerScreen> {
  static const Color teal = Color(0xFF38C6C6);
  static const Color tealDark = Color(0xFF1CA7A7);
  static const Color cream = Color(0xFFF5FAF7);
  static const Color gold = Color(0xFFE8D07A);
  static const Color goldDark = Color(0xFFC6A94F);
  static const Color red = Color(0xFFE8524A);

  final TopicsService _topicsService = TopicsService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _loadingTopics = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final categories = await _topicsService.getCategories();

    String? selected = _selectedCategoryId;
    if (categories.isNotEmpty) {
      final exists = categories.any((c) => c.id == selected);
      selected = exists ? selected : categories.first.id;
    } else {
      selected = null;
    }

    setState(() {
      _categories = categories;
      _selectedCategoryId = selected;
      _loadingCategories = false;
    });

    if (selected != null) {
      await _loadTopics(selected);
    } else {
      setState(() => _topics = []);
    }
  }

  Future<void> _loadTopics(String categoryId) async {
    setState(() => _loadingTopics = true);
    final topics = await _topicsService.getTopicsByCategory(categoryId);
    setState(() {
      _topics = topics;
      _loadingTopics = false;
    });
  }

  Future<void> _showCategorySheet({CategoryModel? category}) async {
    final titleController = TextEditingController(text: category?.title ?? '');
    int order = category?.order ?? (_categories.length + 1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  color: cream,
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
                      category == null ? 'Add Category' : 'Edit Category',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Category Name'),
                    const SizedBox(height: 8),
                    _field(
                      controller: titleController,
                      hint: 'Enter category title',
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('Order'),
                    const SizedBox(height: 8),
                    _orderStepper(
                      value: order,
                      onChanged: (value) => setModalState(() => order = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _secondaryButton(
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _primaryButton(
                            label: category == null ? 'Save' : 'Update',
                            onTap: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) return;

                              final model = CategoryModel(
                                id: category?.id ?? FirebaseFirestore.instance.collection('categories').doc().id,
                                title: title,
                                order: order,
                              );

                              await _topicsService.saveCategory(model);
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
          },
        );
      },
    );
  }

  Future<void> _showTopicSheet({
    required String categoryId,
    TopicModel? topic,
  }) async {
    final nameController = TextEditingController(text: topic?.name ?? '');
    final descController = TextEditingController(text: topic?.desc ?? '');
    int order = topic?.order ?? (_topics.length + 1);
    bool isNew = topic?.isNew ?? true;
    bool isUpdated = topic?.isUpdated ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  color: cream,
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
                      topic == null ? 'Add Topic' : 'Edit Topic',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('Topic Name'),
                    const SizedBox(height: 8),
                    _field(
                      controller: nameController,
                      hint: 'Enter topic name',
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('Description'),
                    const SizedBox(height: 8),
                    _field(
                      controller: descController,
                      hint: 'Short description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _toggleCard(
                            label: 'New',
                            value: isNew,
                            color: const Color(0xFFF45B8C),
                            onTap: () => setModalState(() => isNew = !isNew),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _toggleCard(
                            label: 'Updated',
                            value: isUpdated,
                            color: const Color(0xFFFFA726),
                            onTap: () => setModalState(() => isUpdated = !isUpdated),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('Order'),
                    const SizedBox(height: 8),
                    _orderStepper(
                      value: order,
                      onChanged: (value) => setModalState(() => order = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _secondaryButton(
                            label: 'Cancel',
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _primaryButton(
                            label: topic == null ? 'Save' : 'Update',
                            onTap: () async {
                              final name = nameController.text.trim();
                              final desc = descController.text.trim();
                              if (name.isEmpty || desc.isEmpty) return;

                              final model = TopicModel(
                                id: topic?.id ?? FirebaseFirestore.instance.collection('topics').doc().id,
                                categoryId: categoryId,
                                name: name,
                                desc: desc,
                                isNew: isNew,
                                isUpdated: isUpdated,
                                order: order,
                                createdAt: topic?.createdAt ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              await _topicsService.saveTopic(model);
                              if (!mounted) return;
                              Navigator.pop(context);
                              await _loadTopics(categoryId);
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

  Future<void> _deleteTopic(TopicModel topic) async {
    final confirmed = await _confirmDialog(
      title: 'Delete Topic',
      message: 'Delete "${topic.name}" and its related data?',
    );

    if (confirmed != true) return;

    final db = FirebaseFirestore.instance;

    final questionSnap = await db.collection('questions').where('topicId', isEqualTo: topic.id).get();
    for (final doc in questionSnap.docs) {
      await doc.reference.delete();
    }

    final contentSnap = await db.collection('learning_content').where('topicId', isEqualTo: topic.id).get();
    for (final doc in contentSnap.docs) {
      await doc.reference.delete();
    }

    await _topicsService.deleteTopic(topic.id);
    await _loadTopics(topic.categoryId);
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await _confirmDialog(
      title: 'Delete Category',
      message: 'Delete "${category.title}", all its topics, questions, and content?',
    );

    if (confirmed != true) return;

    final db = FirebaseFirestore.instance;
    final topics = await _topicsService.getTopicsByCategory(category.id);

    for (final topic in topics) {
      final questionSnap = await db.collection('questions').where('topicId', isEqualTo: topic.id).get();
      for (final doc in questionSnap.docs) {
        await doc.reference.delete();
      }

      final contentSnap = await db.collection('learning_content').where('topicId', isEqualTo: topic.id).get();
      for (final doc in contentSnap.docs) {
        await doc.reference.delete();
      }

      await _topicsService.deleteTopic(topic.id);
    }

    await _topicsService.deleteCategory(category.id);
    await _loadCategories();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
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
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories.where((c) => c.id == _selectedCategoryId).cast<CategoryModel?>().firstOrNull;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: teal,
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
                      border: Border.all(color: const Color(0xFFFFF0C2), width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: tealDark,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Manage Categories & Topics',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: goldDark, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF5A7A6A),
                      ),
                      onPressed: () => _showCategorySheet(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _categories.isEmpty
                                ? const Center(
                              child: Text(
                                'No categories yet',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                                : ListView.builder(
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final selected = category.id == _selectedCategoryId;

                                return GestureDetector(
                                  onTap: () async {
                                    setState(() => _selectedCategoryId = category.id);
                                    await _loadTopics(category.id);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? teal.withOpacity(0.12)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected ? teal : const Color(0xFFE5E7EB),
                                        width: selected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.title,
                                                style: TextStyle(
                                                  color: selected ? tealDark : const Color(0xFF111827),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Order ${category.order}',
                                                style: const TextStyle(
                                                  color: Color(0xFF6B7280),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _showCategorySheet(category: category),
                                          icon: const Icon(Icons.edit_rounded, color: tealDark),
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteCategory(category),
                                          icon: const Icon(Icons.delete_rounded, color: red),
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
                  ),
                  Expanded(
                    flex: 5,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedCategory == null
                                      ? 'Topics'
                                      : 'Topics in ${selectedCategory.title}',
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              if (_selectedCategoryId != null)
                                _primaryButton(
                                  label: 'Add Topic',
                                  compact: true,
                                  onTap: () => _showTopicSheet(
                                    categoryId: _selectedCategoryId!,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _selectedCategoryId == null
                                ? const Center(
                              child: Text(
                                'Select a category first',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                                : _loadingTopics
                                ? const Center(child: CircularProgressIndicator())
                                : _topics.isEmpty
                                ? const Center(
                              child: Text(
                                'No topics yet',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                                : ListView.builder(
                              itemCount: _topics.length,
                              itemBuilder: (context, index) {
                                final topic = _topics[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    topic.name,
                                                    style: const TextStyle(
                                                      color: Color(0xFF111827),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                if (topic.isNew)
                                                  const _MiniBadge(
                                                    text: 'NEW',
                                                    color: Color(0xFFF45B8C),
                                                  ),
                                                if (topic.isUpdated)
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 6),
                                                    child: _MiniBadge(
                                                      text: 'UPDATED',
                                                      color: Color(0xFFFFA726),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              topic.desc,
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 12.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Order ${topic.order}',
                                              style: const TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _showTopicSheet(
                                          categoryId: topic.categoryId,
                                          topic: topic,
                                        ),
                                        icon: const Icon(Icons.edit_rounded, color: tealDark),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteTopic(topic),
                                        icon: const Icon(Icons.delete_rounded, color: red),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
      ),
    );
  }

  Widget _orderStepper({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required String label,
    required bool value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: value ? color : const Color(0xFFE5E7EB),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: value ? color : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: value ? color : const Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 42 : 54,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2BBFAA),
              Color(0xFF1FA090),
            ],
          ),
          borderRadius: BorderRadius.circular(compact ? 20 : 28),
          border: Border.all(color: const Color(0xFF16897B), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFF16897B),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 13 : 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}