import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/topic_model.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class CategoryTopicManagerScreen extends StatefulWidget {
  const CategoryTopicManagerScreen({super.key});

  @override
  State<CategoryTopicManagerScreen> createState() => _CategoryTopicManagerScreenState();
}

class _CategoryTopicManagerScreenState extends State<CategoryTopicManagerScreen> {
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

  // ── Data loading ────────────────────────────────────────────

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final categories = await _topicsService.getCategories();
    final selected = categories.isEmpty ? null
        : (categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : categories.first.id);
    setState(() { _categories = categories; _selectedCategoryId = selected; _loadingCategories = false; });
    if (selected != null) await _loadTopics(selected);
    else setState(() => _topics = []);
  }

  Future<void> _loadTopics(String categoryId) async {
    setState(() => _loadingTopics = true);
    final topics = await _topicsService.getTopicsByCategory(categoryId);
    setState(() { _topics = topics; _loadingTopics = false; });
  }

  // ── Sheets ──────────────────────────────────────────────────

  Future<void> _showCategorySheet({CategoryModel? cat}) async {
    final titleCtrl = TextEditingController(text: cat?.title ?? '');
    var order = cat?.order ?? (_categories.length + 1);

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AdminBottomSheet(
        title: cat == null ? 'Add Category' : 'Edit Category',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AdminLabel('Category Name'), const SizedBox(height: 8),
          AdminField(controller: titleCtrl, hint: 'Enter category title'),
          const SizedBox(height: 16),
          const AdminLabel('Order'), const SizedBox(height: 8),
          _OrderStepper(value: order, onChanged: (v) => setS(() => order = v)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: AdminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx))),
            const SizedBox(width: 12),
            Expanded(child: AdminPrimaryButton(
              label: cat == null ? 'Save' : 'Update',
              onTap: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                await _topicsService.saveCategory(CategoryModel(
                  id: cat?.id ?? FirebaseFirestore.instance.collection('categories').doc().id,
                  title: title, order: order,
                ));
                if (!mounted) return;
                Navigator.pop(ctx);
                await _loadCategories();
              },
            )),
          ]),
        ]),
      )),
    );
  }

  Future<void> _showTopicSheet({required String categoryId, TopicModel? topic}) async {
    final nameCtrl = TextEditingController(text: topic?.name ?? '');
    final descCtrl = TextEditingController(text: topic?.desc ?? '');
    var order = topic?.order ?? (_topics.length + 1);
    var isNew = topic?.isNew ?? true;
    var isUpdated = topic?.isUpdated ?? false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AdminBottomSheet(
        title: topic == null ? 'Add Topic' : 'Edit Topic',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AdminLabel('Topic Name'), const SizedBox(height: 8),
          AdminField(controller: nameCtrl, hint: 'Enter topic name'),
          const SizedBox(height: 14),
          const AdminLabel('Description'), const SizedBox(height: 8),
          AdminField(controller: descCtrl, hint: 'Short description', maxLines: 2),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: AdminToggle(label: 'New', value: isNew, color: const Color(0xFFF45B8C), onChanged: (v) => setS(() => isNew = v))),
            const SizedBox(width: 12),
            Expanded(child: AdminToggle(label: 'Updated', value: isUpdated, color: const Color(0xFFFFA726), onChanged: (v) => setS(() => isUpdated = v))),
          ]),
          const SizedBox(height: 14),
          const AdminLabel('Order'), const SizedBox(height: 8),
          _OrderStepper(value: order, onChanged: (v) => setS(() => order = v)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: AdminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx))),
            const SizedBox(width: 12),
            Expanded(child: AdminPrimaryButton(
              label: topic == null ? 'Save' : 'Update',
              onTap: () async {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (name.isEmpty || desc.isEmpty) return;
                await _topicsService.saveTopic(TopicModel(
                  id: topic?.id ?? FirebaseFirestore.instance.collection('topics').doc().id,
                  categoryId: categoryId, name: name, desc: desc,
                  isNew: isNew, isUpdated: isUpdated, order: order,
                  createdAt: topic?.createdAt ?? DateTime.now(), updatedAt: DateTime.now(),
                ));
                if (!mounted) return;
                Navigator.pop(ctx);
                await _loadTopics(categoryId);
              },
            )),
          ]),
        ]),
      )),
    );
  }

  // ── Delete ──────────────────────────────────────────────────

  Future<void> _deleteTopic(TopicModel topic) async {
    if (!await _confirm('Delete "${topic.name}"?', 'Related questions and content will also be deleted.')) return;
    final db = FirebaseFirestore.instance;
    for (final col in ['questions', 'learning_content']) {
      final snap = await db.collection(col).where('topicId', isEqualTo: topic.id).get();
      for (final d in snap.docs) await d.reference.delete();
    }
    await _topicsService.deleteTopic(topic.id);
    await _loadTopics(topic.categoryId);
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    if (!await _confirm('Delete "${cat.title}"?', 'All topics, questions, and content will be deleted.')) return;
    final db = FirebaseFirestore.instance;
    final topics = await _topicsService.getTopicsByCategory(cat.id);
    for (final t in topics) {
      for (final col in ['questions', 'learning_content']) {
        final snap = await db.collection(col).where('topicId', isEqualTo: t.id).get();
        for (final d in snap.docs) await d.reference.delete();
      }
      await _topicsService.deleteTopic(t.id);
    }
    await _topicsService.deleteCategory(cat.id);
    await _loadCategories();
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title), content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AdminColors.red))),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selCat = _categories.cast<CategoryModel?>()
        .firstWhere((c) => c?.id == _selectedCategoryId, orElse: () => null);

    return Scaffold(
      backgroundColor: AdminColors.cream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: AdminColors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text('Categories & Topics', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              // Add category button
              Container(
                decoration: BoxDecoration(color: AdminColors.yellow, shape: BoxShape.circle,
                    border: Border.all(color: AdminColors.yellowDark, width: 2)),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF5A7A6A)),
                  onPressed: _showCategorySheet,
                  tooltip: 'Add Category',
                ),
              ),
            ]),
          ),

          // Split view
          Expanded(
            child: _loadingCategories
                ? const Center(child: CircularProgressIndicator(color: AdminColors.teal))
                : Row(children: [
              // Categories panel
              _Panel(
                width: 200,
                margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Categories', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _categories.isEmpty
                        ? const Center(child: Text('No categories', style: TextStyle(color: Color(0xFF9CA3AF))))
                        : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = cat.id == _selectedCategoryId;
                        return GestureDetector(
                          onTap: () async { setState(() => _selectedCategoryId = cat.id); await _loadTopics(cat.id); },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AdminColors.teal.withOpacity(0.1) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? AdminColors.teal : const Color(0xFFE5E7EB), width: sel ? 2 : 1),
                            ),
                            child: Row(children: [
                              Expanded(child: Text(cat.title, style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13,
                                  color: sel ? AdminColors.darkTeal : const Color(0xFF111827)))),
                              GestureDetector(onTap: () => _showCategorySheet(cat: cat),
                                  child: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 15)),
                              const SizedBox(width: 4),
                              GestureDetector(onTap: () => _deleteCategory(cat),
                                  child: const Icon(Icons.delete_rounded, color: AdminColors.red, size: 15)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),

              // Topics panel
              Expanded(
                child: _Panel(
                  margin: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(
                        selCat == null ? 'Topics' : 'Topics in ${selCat.title}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
                      )),
                      if (_selectedCategoryId != null)
                        TextButton.icon(
                          onPressed: () => _showTopicSheet(categoryId: _selectedCategoryId!),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AdminColors.teal),
                        ),
                    ]),
                    const Divider(height: 16),
                    Expanded(
                      child: _selectedCategoryId == null
                          ? const Center(child: Text('Select a category', style: TextStyle(color: Color(0xFF9CA3AF))))
                          : _loadingTopics
                          ? const Center(child: CircularProgressIndicator(color: AdminColors.teal))
                          : _topics.isEmpty
                          ? const Center(child: Text('No topics yet', style: TextStyle(color: Color(0xFF9CA3AF))))
                          : ListView.builder(
                        itemCount: _topics.length,
                        itemBuilder: (_, i) {
                          final topic = _topics[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                            child: Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)))),
                                  if (topic.isNew) AdminBadge(text: 'NEW', color: const Color(0xFFF45B8C)),
                                  if (topic.isUpdated) AdminBadge(text: 'UPD', color: const Color(0xFFFFA726)),
                                ]),
                                Text(topic.desc, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                              ])),
                              IconButton(icon: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 16),
                                  onPressed: () => _showTopicSheet(categoryId: topic.categoryId, topic: topic)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: AdminColors.red, size: 16),
                                  onPressed: () => _deleteTopic(topic)),
                            ]),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Local widgets (only used here) ─────────────────────────────

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final double? width;
  const _Panel({required this.child, required this.margin, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _OrderStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _OrderStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        IconButton(onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_rounded)),
        Expanded(child: Center(child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_rounded)),
      ]),
    );
  }
}