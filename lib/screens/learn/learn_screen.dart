import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/learning_content_model.dart';
import '../../services/learning_service.dart';
import '../../services/topics_service.dart';
import 'article_screen.dart';
import 'video_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  static const teal = Color(0xFF2BBFAA);

  final LearningService _learningService = LearningService();
  final TopicsService _topicsService = TopicsService();

  List<CategoryModel> _categories = [];
  String _selectedCatId = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _topicsService.getCategories();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  void _openContent(LearningContentModel item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => item.type == ContentType.video
          ? VideoScreen(content: item)
          : ArticleScreen(content: item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Teal header with category chips
            Container(
              color: teal,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Learn', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  const Text('Explore articles and videos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: _loading
                        ? const SizedBox.shrink()
                        : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Chip(label: 'All', selected: _selectedCatId == 'all', onTap: () => setState(() => _selectedCatId = 'all')),
                        ..._categories.map((cat) => _Chip(
                          label: cat.title,
                          selected: _selectedCatId == cat.id,
                          onTap: () => setState(() => _selectedCatId = cat.id),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Content list
            Expanded(
              child: StreamBuilder<List<LearningContentModel>>(
                stream: _selectedCatId == 'all'
                    ? _learningService.getAllContent()
                    : _learningService.getContentByCategory(_selectedCatId),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: teal));

                  final items = snap.data!;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: teal.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.menu_book_rounded, color: teal, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text('No content yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          const Text('Check back soon!', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ContentCard(item: items[i], onTap: () => _openContent(items[i])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white : Colors.white38, width: 1.5),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFF1A9E8F) : Colors.white,
          fontWeight: FontWeight.bold, fontSize: 13,
        )),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final LearningContentModel item;
  final VoidCallback onTap;
  const _ContentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == ContentType.video;
    final isImage = item.type == ContentType.infographic;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              child: item.thumbnailUrl.isNotEmpty
                  ? Image.network(item.thumbnailUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(isVideo, isImage))
                  : _placeholder(isVideo, isImage),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _TypeBadge(type: item.type),
                    if (!isVideo && item.readTimeMinutes > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, color: AppColors.textLight, size: 12),
                      const SizedBox(width: 3),
                      Text('${item.readTimeMinutes} min read', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isVideo, bool isImage) {
    return Container(
      height: 140, width: double.infinity,
      color: const Color(0xFFE8F5F3),
      child: Center(child: Icon(
        isVideo ? Icons.play_circle_rounded : isImage ? Icons.image_rounded : Icons.article_rounded,
        color: const Color(0xFF2BBFAA), size: 48,
      )),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final ContentType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isVideo = type == ContentType.video;
    final isImage = type == ContentType.infographic;
    final color = isVideo ? const Color(0xFFE8524A) : isImage ? const Color(0xFFFFB300) : const Color(0xFF2BBFAA);
    final label = isVideo ? 'VIDEO' : isImage ? 'IMAGE' : 'ARTICLE';
    final icon = isVideo ? Icons.play_circle_rounded : isImage ? Icons.image_rounded : Icons.article_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
      ]),
    );
  }
}