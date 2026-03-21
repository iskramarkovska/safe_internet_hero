import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/learning_content_model.dart';
import '../services/learning_service.dart';
import 'article_screen.dart';
import 'video_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final LearningService _service = LearningService();
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'color': const Color(0xFF00D4FF)},
    {'id': 'privacy', 'label': 'Privacy', 'color': const Color(0xFF7C4DFF)},
    {'id': 'passwords', 'label': 'Passwords', 'color': const Color(0xFF00BCD4)},
    {'id': 'cyberbullying', 'label': 'Cyberbullying', 'color': const Color(0xFFFF5252)},
    {'id': 'social_media', 'label': 'Social Media', 'color': const Color(0xFFFFD740)},
    {'id': 'phishing', 'label': 'Phishing', 'color': const Color(0xFFFF6D00)},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Learn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // Category filter
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['id'];
                  final color = cat['color'] as Color;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: TextStyle(
                          color: isSelected ? color : Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Content list
            Expanded(
              child: StreamBuilder<List<LearningContentModel>>(
                stream: _selectedCategory == 'all'
                    ? _service.getContentByCategory('all')
                    : _service.getContentByCategory(_selectedCategory),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // For 'all' fetch all content
                  return _selectedCategory == 'all'
                      ? _buildAllContent()
                      : _buildContentList(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllContent() {
    return StreamBuilder<List<LearningContentModel>>(
      stream: FirebaseFirestore.instance
          .collection('learning_content')
          .snapshots()
          .map((snap) => snap.docs
          .map((doc) =>
          LearningContentModel.fromMap(doc.data()))
          .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContentList(snapshot.data!);
      },
    );
  }

  Widget _buildContentList(List<LearningContentModel> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📚', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No content yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Check back soon!',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildContentCard(items[index]),
    );
  }

  Widget _buildContentCard(LearningContentModel item) {
    final typeIcon = item.type == ContentType.video
        ? '▶️'
        : item.type == ContentType.infographic
        ? '🖼️'
        : '📄';

    final typeLabel = item.type == ContentType.video
        ? 'Video'
        : item.type == ContentType.infographic
        ? 'Infographic'
        : '${item.readTimeMinutes} min read';

    return GestureDetector(
      onTap: () {
        if (item.type == ContentType.video) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoScreen(content: item)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticleScreen(content: item)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (item.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16213E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16213E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.white24, size: 40),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(typeIcon,
                      style: const TextStyle(fontSize: 40)),
                ),
              ),

            // Content info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.categoryId,
                          style: const TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$typeIcon $typeLabel',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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