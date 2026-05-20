import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';

class ArticleScreen extends StatelessWidget {
  final LearningContentModel content;
  const ArticleScreen({super.key, required this.content});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Article', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.thumbnailUrl.isNotEmpty)
                      Image.network(content.thumbnailUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink()),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.article_rounded, color: AppColors.teal, size: 13),
                                SizedBox(width: 4),
                                Text('ARTICLE', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold, fontSize: 10)),
                              ]),
                            ),
                            if (content.readTimeMinutes > 0) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.access_time_rounded, color: AppColors.textLight, size: 13),
                              const SizedBox(width: 4),
                              Text('${content.readTimeMinutes} min read',
                                  style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ],
                          ]),
                          const SizedBox(height: 14),
                          Text(content.title, style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary, height: 1.3)),
                          const SizedBox(height: 10),
                          if (content.description.isNotEmpty)
                            Text(content.description, style: const TextStyle(
                                fontSize: 15, color: AppColors.textSecondary, height: 1.5)),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),
                          Text(content.content, style: const TextStyle(
                              fontSize: 16, color: AppColors.textPrimary, height: 1.8)),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}