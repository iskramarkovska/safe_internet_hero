import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';

class VideoScreen extends StatelessWidget {
  final LearningContentModel content;
  const VideoScreen({super.key, required this.content});

  static const teal = Color(0xFF2BBFAA);

  Future<void> _openVideo() async {
    final videoId = content.content.trim();
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
    final thumbUrl = 'https://img.youtube.com/vi/${content.content.trim()}/maxresdefault.jpg';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: teal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Video', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail + play button
                    GestureDetector(
                      onTap: _openVideo,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(thumbUrl,
                              height: 210, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 210,
                                decoration: BoxDecoration(
                                  color: teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: teal, size: 64)),
                              ),
                            ),
                          ),
                          Container(
                            width: 64, height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(child: Text('Tap to open in YouTube',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12))),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8524A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.play_circle_rounded, color: Color(0xFFE8524A), size: 13),
                        SizedBox(width: 4),
                        Text('VIDEO', style: TextStyle(color: Color(0xFFE8524A), fontWeight: FontWeight.bold, fontSize: 10)),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    Text(content.title, style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.3)),
                    const SizedBox(height: 10),

                    if (content.description.isNotEmpty)
                      Text(content.description, style: const TextStyle(
                          fontSize: 15, color: AppColors.textSecondary, height: 1.5)),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: _openVideo,
                      child: Container(
                        height: 52, width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8524A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC62828), width: 2),
                          boxShadow: const [BoxShadow(color: Color(0xFFC62828), offset: Offset(0, 4), blurRadius: 0)],
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text('Watch on YouTube', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 40),
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