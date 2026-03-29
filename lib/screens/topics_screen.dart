import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';
import 'quiz_screen.dart';
import 'notifications_screen.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      'title': 'Privacy',
      'categoryId': 'privacy',
      'emoji': '🔒',
      'color': AppColors.categoryPrivacy,
      'topics': [
        {'name': 'Personal Info', 'emoji': '🪪', 'topicId': 'personal_info'},
        {'name': 'Sharing Online', 'emoji': '📤', 'topicId': 'sharing_online'},
        {'name': 'Digital Footprint', 'emoji': '👣', 'topicId': 'digital_footprint'},
        {'name': 'App Permissions', 'emoji': '📱', 'topicId': 'app_permissions'},
      ],
    },
    {
      'title': 'Passwords',
      'categoryId': 'passwords',
      'emoji': '🔐',
      'color': AppColors.categoryPasswords,
      'topics': [
        {'name': 'Strong Passwords', 'emoji': '💪', 'topicId': 'strong_passwords'},
        {'name': 'Two Factor Auth', 'emoji': '🗝️', 'topicId': 'two_factor_auth'},
        {'name': 'Password Safety', 'emoji': '🛡️', 'topicId': 'password_safety'},
        {'name': 'Password Manager', 'emoji': '💾', 'topicId': 'password_manager'},
      ],
    },
    {
      'title': 'Cyberbullying',
      'categoryId': 'cyberbullying',
      'emoji': '💙',
      'color': AppColors.categoryCyberbullying,
      'topics': [
        {'name': 'Spot Bullying', 'emoji': '👀', 'topicId': 'spot_bullying'},
        {'name': 'Be an Upstander', 'emoji': '✊', 'topicId': 'be_an_upstander'},
        {'name': 'Report & Block', 'emoji': '🚫', 'topicId': 'report_block'},
        {'name': 'Cyber Law', 'emoji': '⚖️', 'topicId': 'cyber_law'},
      ],
    },
    {
      'title': 'Social Media',
      'categoryId': 'social_media',
      'emoji': '📸',
      'color': AppColors.categorySocialMedia,
      'topics': [
        {'name': 'Privacy Settings', 'emoji': '⚙️', 'topicId': 'privacy_settings'},
        {'name': 'Strangers Online', 'emoji': '👤', 'topicId': 'strangers_online'},
        {'name': 'Geo Tagging', 'emoji': '📍', 'topicId': 'geo_tagging'},
        {'name': 'Screen Time', 'emoji': '⏱️', 'topicId': 'screen_time'},
      ],
    },
    {
      'title': 'Phishing',
      'categoryId': 'phishing',
      'emoji': '🎣',
      'color': AppColors.categoryPhishing,
      'topics': [
        {'name': 'Spot Scams', 'emoji': '🔍', 'topicId': 'spot_scams'},
        {'name': 'Fake Links', 'emoji': '🔗', 'topicId': 'fake_links'},
        {'name': 'Email Safety', 'emoji': '📧', 'topicId': 'email_safety'},
        {'name': 'Spear Phishing', 'emoji': '🎯', 'topicId': 'spear_phishing'},
      ],
    },
  ];

  Future<bool> _isTopicCompleted(
      UserModel? user, String categoryId, String topicId) async {
    if (user == null) return false;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
        categoryId: categoryId, topicId: topicId);
    if (total == 0) return false;
    final all =
    await service.getQuestions(categoryId: categoryId, topicId: topicId);
    return all.where((q) => user.answeredQuestions.contains(q.id)).length >=
        total;
  }

  void _openQuiz(
      BuildContext context, {
        required String categoryId,
        required String categoryName,
        required String topicId,
        required String topicName,
        required Color color,
      }) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    if (!isGuest && user != null) {
      final service = QuestionService();
      final total = await service.getTotalQuestionsCount(
          categoryId: categoryId, topicId: topicId);
      final all = await service.getQuestions(
          categoryId: categoryId, topicId: topicId);
      final answered =
          all.where((q) => user.answeredQuestions.contains(q.id)).length;

      if (total > 0 && answered >= total) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Topic Completed!',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('You\'ve answered all questions in $topicName!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: color),
                    child: const Text('Back to Topics'),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          topicId: topicId,
          topicName: topicName,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest
                              ? 'Hi, Guest 👋'
                              : 'Hi, ${user?.username ?? 'Hero'} 👋',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const Text(
                          'What will you learn today?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isGuest)
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined,
                                    color: AppColors.textSecondary),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const NotificationsScreen()),
                                ),
                              ),
                              if (user != null &&
                                  user.friendRequests.isNotEmpty)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.wrong,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${user.friendRequests.length}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: AppColors.textSecondary),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('Log out?'),
                                content: const Text(
                                    'Are you sure you want to log out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Log out',
                                        style:
                                        TextStyle(color: AppColors.wrong)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              context.read<AuthProvider>().logout();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Stars banner
            if (!isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2BBFAA), Color(0xFF4DD0C4)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your stars',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              '${user?.totalStars ?? 0} stars earned',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Guest banner
            if (isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8524A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE8524A).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Text('👤', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Playing as Guest — results won\'t be saved',
                            style: TextStyle(
                              color: Color(0xFFE8524A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Categories + vertical topic cards
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final cat = _categories[index];
                  final color = cat['color'] as Color;
                  final topics =
                  cat['topics'] as List<Map<String, String>>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(cat['emoji'] as String,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              cat['title'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...topics.map((topic) => isGuest
                          ? _TopicCard(
                        topic: topic,
                        color: color,
                        isDone: false,
                        onTap: () => _openQuiz(
                          context,
                          categoryId: cat['categoryId'] as String,
                          categoryName: cat['title'] as String,
                          topicId: topic['topicId']!,
                          topicName: topic['name']!,
                          color: color,
                        ),
                      )
                          : FutureBuilder<bool>(
                        future: _isTopicCompleted(
                          user,
                          cat['categoryId'] as String,
                          topic['topicId']!,
                        ),
                        builder: (context, snap) => _TopicCard(
                          topic: topic,
                          color: color,
                          isDone: snap.data ?? false,
                          onTap: () => _openQuiz(
                            context,
                            categoryId: cat['categoryId'] as String,
                            categoryName: cat['title'] as String,
                            topicId: topic['topicId']!,
                            topicName: topic['name']!,
                            color: color,
                          ),
                        ),
                      )),
                    ],
                  );
                },
                childCount: _categories.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Map<String, String> topic;
  final Color color;
  final bool isDone;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.color,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDone ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? color : const Color(0xFFB2DFDB),
            width: isDone ? 2 : 1,
          ),
          boxShadow: isDone
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(topic['emoji']!,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                topic['name']!,
                style: TextStyle(
                  color: isDone ? color : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            isDone
                ? Icon(Icons.check_circle_rounded, color: color, size: 22)
                : const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight, size: 16),
          ],
        ),
      ),
    );
  }
}