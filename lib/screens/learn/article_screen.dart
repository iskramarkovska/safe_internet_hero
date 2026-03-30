import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/learning_content_model.dart';

class ArticleScreen extends StatelessWidget {
  final LearningContentModel content;

  const ArticleScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          content.categoryId,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (content.thumbnailUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: content.thumbnailUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Title
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Meta
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${content.readTimeMinutes} min read',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    content.categoryId,
                    style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 20),

            // Article content
            Text(
              content.content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}