import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../models/topic_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import '../../widgets/admin_widgets.dart';

class ManageLearningContentScreen extends StatefulWidget {
  const ManageLearningContentScreen({super.key});

  @override
  State<ManageLearningContentScreen> createState() => _ManageLearningContentScreenState();
}

class _ManageLearningContentScreenState extends State<ManageLearningContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<_AddContentFormState>();

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
            // Header
            Container(
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
                      child: Text('Learning Content', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 48),
                  ]),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AdminColors.yellow,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [Tab(text: 'Add Content'), Tab(text: 'All Content')],
                ),
              ]),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AddContentForm(key: _formKey),
                  _ContentList(
                    onEdit: (item) {
                      _formKey.currentState?.loadForEdit(item);
                      _tabController.animateTo(0);
                    },
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

// ─────────────────────────────────────────────────────────────
// ADD / EDIT FORM
// ─────────────────────────────────────────────────────────────

class _AddContentForm extends StatefulWidget {
  const _AddContentForm({super.key});

  @override
  State<_AddContentForm> createState() => _AddContentFormState();
}

class _AddContentFormState extends State<_AddContentForm> {
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _contentCtrl     = TextEditingController();
  final _thumbCtrl       = TextEditingController();
  final _readTimeCtrl    = TextEditingController();

  final TopicsService _topicsService = TopicsService();
  final LearningService _learningService = LearningService();

  List<CategoryModel> _categories = [];
  List<TopicModel> _topics = [];
  String? _categoryId;
  String? _topicId;
  bool _loading = true;
  bool _saving = false;
  ContentType _type = ContentType.article;
  LearningContentModel? _editing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _contentCtrl.dispose();
    _thumbCtrl.dispose(); _readTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await _topicsService.getCategories();
      if (!mounted) return;
      setState(() { _categories = cats; _categoryId = cats.isNotEmpty ? cats.first.id : null; });
      if (_categoryId != null) {
        await _loadTopics(_categoryId!);
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTopics(String catId) async {
    if (mounted) setState(() => _loading = true);
    try {
      final topics = await _topicsService.getTopicsByCategory(catId);
      if (!mounted) return;
      setState(() { _topics = topics; _topicId = topics.isNotEmpty ? topics.first.id : null; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Called from parent via GlobalKey when user taps edit in the list
  void loadForEdit(LearningContentModel item) {
    setState(() {
      _editing = item;
      _titleCtrl.text    = item.title;
      _descCtrl.text     = item.description;
      _contentCtrl.text  = item.content;
      _thumbCtrl.text    = item.thumbnailUrl;
      _readTimeCtrl.text = item.readTimeMinutes > 0 ? '${item.readTimeMinutes}' : '';
      _type              = item.type;
      _categoryId        = item.categoryId;
      _topicId           = item.topicId;
    });
    _loadTopics(item.categoryId);
  }

  void _clearForm() {
    _titleCtrl.clear(); _descCtrl.clear(); _contentCtrl.clear();
    _thumbCtrl.clear(); _readTimeCtrl.clear();
    setState(() { _editing = null; _type = ContentType.article; });
  }

  Future<void> _save() async {
    if (_categoryId == null || _topicId == null) { _snack('Select category and topic', isError: true); return; }
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) { _snack('Title and content are required', isError: true); return; }

    setState(() => _saving = true);
    try {
      final model = LearningContentModel(
        id: _editing?.id ?? '',
        categoryId: _categoryId!, topicId: _topicId!,
        title: _titleCtrl.text.trim(), description: _descCtrl.text.trim(),
        type: _type, content: _contentCtrl.text.trim(),
        thumbnailUrl: _thumbCtrl.text.trim(),
        readTimeMinutes: int.tryParse(_readTimeCtrl.text.trim()) ?? 0,
        createdAt: _editing?.createdAt ?? DateTime.now(),
      );
      _editing != null ? await _learningService.updateContent(model) : await _learningService.saveContent(model);
      _clearForm();
      setState(() => _saving = false);
      _snack(_editing != null ? 'Content updated!' : 'Content saved!');
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_editing != null) AdminEditBanner(title: _editing!.title, onClear: _clearForm),

        // Category + Topic
        AdminCard(title: 'Where does this content belong?', child: Column(
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

        // Content type
        AdminCard(title: 'Content type', child: Row(children: [
          Expanded(child: AdminTypeButton(label: 'Article', icon: Icons.article_rounded,
              selected: _type == ContentType.article, onTap: () => setState(() => _type = ContentType.article))),
          const SizedBox(width: 8),
          Expanded(child: AdminTypeButton(label: 'Video', icon: Icons.play_circle_rounded,
              selected: _type == ContentType.video, onTap: () => setState(() => _type = ContentType.video))),
          const SizedBox(width: 8),
          Expanded(child: AdminTypeButton(label: 'Image', icon: Icons.image_rounded,
              selected: _type == ContentType.infographic, onTap: () => setState(() => _type = ContentType.infographic))),
        ])),
        const SizedBox(height: 14),

        // Details
        AdminCard(title: 'Content details', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminLabel('Title'), const SizedBox(height: 8),
            AdminField(controller: _titleCtrl, hint: 'Content title'),
            const SizedBox(height: 14),
            const AdminLabel('Description'), const SizedBox(height: 8),
            AdminField(controller: _descCtrl, hint: 'Short description shown on card', maxLines: 2),
            const SizedBox(height: 14),
            AdminLabel(_type == ContentType.video ? 'YouTube Video ID'
                : _type == ContentType.infographic ? 'Image URL' : 'Article text'),
            const SizedBox(height: 8),
            AdminField(controller: _contentCtrl,
                maxLines: _type == ContentType.article ? 8 : 1,
                hint: _type == ContentType.video ? 'e.g. dQw4w9WgXcQ'
                    : _type == ContentType.infographic ? 'https://example.com/image.jpg'
                    : 'Write your article here...'),
            const SizedBox(height: 14),
            const AdminLabel('Thumbnail URL (optional)'), const SizedBox(height: 8),
            AdminField(controller: _thumbCtrl, hint: 'https://example.com/thumbnail.jpg'),
            if (_type == ContentType.article) ...[
              const SizedBox(height: 14),
              const AdminLabel('Read time (minutes)'), const SizedBox(height: 8),
              AdminField(controller: _readTimeCtrl, hint: 'e.g. 3', keyboardType: TextInputType.number),
            ],
          ],
        )),
        const SizedBox(height: 16),
        AdminPrimaryButton(
            label: _saving ? 'Saving...' : (_editing != null ? 'Update Content' : 'Save Content'),
            onTap: _saving ? () {} : _save),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONTENT LIST
// ─────────────────────────────────────────────────────────────

class _ContentList extends StatelessWidget {
  final void Function(LearningContentModel) onEdit;
  const _ContentList({required this.onEdit});

  Future<void> _delete(BuildContext context, LearningContentModel item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Content'),
        content: Text('Delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AdminColors.red))),
        ],
      ),
    );
    if (ok == true) {
      await LearningService().deleteContent(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted'), backgroundColor: AdminColors.darkTeal));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LearningContentModel>>(
      stream: LearningService().getAllContent(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AdminColors.teal));
        final items = snap.data!;
        if (items.isEmpty) {
          return const AdminEmptyState(
              icon: Icons.library_books_rounded,
              title: 'No content yet',
              subtitle: 'Add some from the "Add Content" tab');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isVideo = item.type == ContentType.video;
            final isImage = item.type == ContentType.infographic;
            final typeColor  = isVideo ? AdminColors.red : isImage ? const Color(0xFFFFB300) : AdminColors.teal;
            final typeLabel  = isVideo ? 'VIDEO' : isImage ? 'IMAGE' : 'ARTICLE';
            final typeIcon   = isVideo ? Icons.play_circle_rounded : isImage ? Icons.image_rounded : Icons.article_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]),
              child: Row(children: [
                Container(width: 46, height: 46,
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(typeIcon, color: typeColor, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    AdminBadge(text: typeLabel, color: typeColor),
                    const SizedBox(width: 6),
                    Text(item.categoryId, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  if (item.description.isNotEmpty)
                    Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ])),
                IconButton(icon: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 20), onPressed: () => onEdit(item)),
                IconButton(icon: const Icon(Icons.delete_rounded, color: AdminColors.red, size: 20), onPressed: () => _delete(context, item)),
              ]),
            );
          },
        );
      },
    );
  }
}