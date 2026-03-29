import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';
import 'quiz_screen.dart';

class _Topic {
  final String name;
  final String desc;
  final IconData icon;
  final String topicId;
  const _Topic({required this.name, required this.desc, required this.icon, required this.topicId});
}

class _Category {
  final String title;
  final String categoryId;
  final IconData icon;
  final Color color;
  final Color darkColor;
  final List<_Topic> topics;
  const _Category({required this.title, required this.categoryId, required this.icon, required this.color, required this.darkColor, required this.topics});
}

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  static const teal = Color(0xFF2BBFAA);
  static const darkTeal = Color(0xFF1A9E8F);

  static final List<_Category> _categories = [
    _Category(title: 'Privacy', categoryId: 'privacy', icon: Icons.lock_rounded, color: const Color(0xFF2BBFAA), darkColor: const Color(0xFF1A9E8F),
        topics: [
          _Topic(name: 'Personal Info', desc: 'What you should never share online', icon: Icons.badge_rounded, topicId: 'personal_info'),
          _Topic(name: 'Sharing Online', desc: 'Think before you post', icon: Icons.share_rounded, topicId: 'sharing_online'),
          _Topic(name: 'Digital Footprint', desc: 'The trail you leave online', icon: Icons.track_changes_rounded, topicId: 'digital_footprint'),
          _Topic(name: 'App Permissions', desc: 'Why apps ask for access', icon: Icons.phone_android_rounded, topicId: 'app_permissions'),
        ]),
    _Category(title: 'Passwords', categoryId: 'passwords', icon: Icons.key_rounded, color: const Color(0xFF26C6DA), darkColor: const Color(0xFF00838F),
        topics: [
          _Topic(name: 'Strong Passwords', desc: 'How to create unbreakable passwords', icon: Icons.security_rounded, topicId: 'strong_passwords'),
          _Topic(name: 'Two Factor Auth', desc: 'Double protection for your account', icon: Icons.verified_user_rounded, topicId: 'two_factor_auth'),
          _Topic(name: 'Password Safety', desc: 'Common password mistakes to avoid', icon: Icons.shield_rounded, topicId: 'password_safety'),
          _Topic(name: 'Password Manager', desc: 'Tools to store passwords safely', icon: Icons.folder_rounded, topicId: 'password_manager'),
        ]),
    _Category(title: 'Cyberbullying', categoryId: 'cyberbullying', icon: Icons.favorite_rounded, color: const Color(0xFF42C8B0), darkColor: const Color(0xFF1A9E8F),
        topics: [
          _Topic(name: 'Spot Bullying', desc: 'How to recognise online bullying', icon: Icons.visibility_rounded, topicId: 'spot_bullying'),
          _Topic(name: 'Be an Upstander', desc: 'Stand up for others online', icon: Icons.emoji_people_rounded, topicId: 'be_an_upstander'),
          _Topic(name: 'Report & Block', desc: 'How and when to report', icon: Icons.block_rounded, topicId: 'report_block'),
          _Topic(name: 'Cyber Law', desc: 'Legal consequences of bullying', icon: Icons.gavel_rounded, topicId: 'cyber_law'),
        ]),
    _Category(title: 'Social Media', categoryId: 'social_media', icon: Icons.photo_camera_rounded, color: const Color(0xFF2BBFAA), darkColor: const Color(0xFF00897B),
        topics: [
          _Topic(name: 'Privacy Settings', desc: 'Lock down your profile', icon: Icons.settings_rounded, topicId: 'privacy_settings'),
          _Topic(name: 'Strangers Online', desc: 'Who can you trust online?', icon: Icons.person_off_rounded, topicId: 'strangers_online'),
          _Topic(name: 'Geo Tagging', desc: 'Why sharing location is risky', icon: Icons.location_off_rounded, topicId: 'geo_tagging'),
          _Topic(name: 'Screen Time', desc: 'Healthy habits for screen use', icon: Icons.timer_rounded, topicId: 'screen_time'),
        ]),
    _Category(title: 'Phishing', categoryId: 'phishing', icon: Icons.phishing_rounded, color: const Color(0xFF1ABDA4), darkColor: const Color(0xFF00796B),
        topics: [
          _Topic(name: 'Spot Scams', desc: 'Red flags to watch for', icon: Icons.search_rounded, topicId: 'spot_scams'),
          _Topic(name: 'Fake Links', desc: 'Never click suspicious links', icon: Icons.link_off_rounded, topicId: 'fake_links'),
          _Topic(name: 'Email Safety', desc: 'Spot fake emails instantly', icon: Icons.mark_email_read_rounded, topicId: 'email_safety'),
          _Topic(name: 'Spear Phishing', desc: 'Targeted attacks explained', icon: Icons.gps_fixed_rounded, topicId: 'spear_phishing'),
        ]),
  ];

  Future<bool> _isTopicCompleted(UserModel? user, String categoryId, String topicId) async {
    if (user == null) return false;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(categoryId: categoryId, topicId: topicId);
    if (total == 0) return false;
    final all = await service.getQuestions(categoryId: categoryId, topicId: topicId);
    return all.where((q) => user.answeredQuestions.contains(q.id)).length >= total;
  }

  void _openQuiz(BuildContext context, {required _Category cat, required _Topic topic}) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    if (!isGuest && user != null) {
      final service = QuestionService();
      final total = await service.getTotalQuestionsCount(categoryId: cat.categoryId, topicId: topic.topicId);
      final all = await service.getQuestions(categoryId: cat.categoryId, topicId: topic.topicId);
      final answered = all.where((q) => user.answeredQuestions.contains(q.id)).length;
      if (total > 0 && answered >= total) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Topic Completed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('All questions in ${topic.name} answered!', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: teal), child: const Text('Back'))),
              ],
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizScreen(categoryId: cat.categoryId, categoryName: cat.title, topicId: topic.topicId, topicName: topic.name, color: cat.color),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

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
                    child: Text('Topics List', textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Select a topic pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8C84A),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFC8A830), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFC8A830), offset: Offset(0, 3), blurRadius: 0),
                        ],
                      ),
                      child: const Text('Select a topic',
                          style: TextStyle(color: Color(0xFF5A7A6A), fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  for (final cat in _categories) ...[
                    for (final topic in cat.topics)
                      isGuest
                          ? _TopicCard(topic: topic, cat: cat, isDone: false,
                          onTap: () => _openQuiz(context, cat: cat, topic: topic))
                          : FutureBuilder<bool>(
                        future: _isTopicCompleted(user, cat.categoryId, topic.topicId),
                        builder: (context, snap) => _TopicCard(
                          topic: topic, cat: cat, isDone: snap.data ?? false,
                          onTap: () => _openQuiz(context, cat: cat, topic: topic),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _Topic topic;
  final _Category cat;
  final bool isDone;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.cat, required this.isDone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, top: 18),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main teal card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cat.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cat.darkColor, width: 2),
                boxShadow: [
                  BoxShadow(color: cat.darkColor, offset: const Offset(0, 5), blurRadius: 0),
                  const BoxShadow(color: Colors.black12, offset: Offset(0, 8), blurRadius: 8),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Yellow pill with topic name
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C84A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFC8A830), width: 1.5),
                    ),
                    child: Text(
                      topic.name,
                      style: const TextStyle(
                        color: Color(0xFF5A4A1A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    topic.desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                  if (isDone) ...[
                    const SizedBox(height: 6),
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),

            // Icon circle — overflow top left
            Positioned(
              top: -18,
              left: 12,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: cat.darkColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: cat.darkColor, offset: const Offset(0, 3), blurRadius: 0),
                    const BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(topic.icon, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}