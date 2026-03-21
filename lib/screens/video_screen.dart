import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/learning_content_model.dart';

class VideoScreen extends StatelessWidget {
  final LearningContentModel content;

  const VideoScreen({super.key, required this.content});

  Future<void> _openVideo() async {
    final videoId = content.content.trim();

    // Try YouTube app first
    final youtubeApp = Uri.parse('vnd.youtube:$videoId');
    final youtubeWeb = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    if (await canLaunchUrl(youtubeApp)) {
      await launchUrl(youtubeApp);
    } else if (await canLaunchUrl(youtubeWeb)) {
      await launchUrl(youtubeWeb, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(youtubeWeb, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          content.title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button
            GestureDetector(
              onTap: _openVideo,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://img.youtube.com/vi/${content.content.trim()}/maxresdefault.jpg',                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white54, size: 64),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to open in YouTube',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              content.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            const SizedBox(height: 16),

            // Description
            Text(
              content.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}