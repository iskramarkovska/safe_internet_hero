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
    final all = await service.getQuestions(
        categoryId: categoryId, topicId: topicId);
    return all.where((q) => user.answeredQuestions.contains(q.id)).length >=
        total;
  }

  void _openQuiz(BuildContext context,
      {required String categoryId,
        required String categoryName,
        required String topicId,
        required String topicName,
        required Color color}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
        categoryId: categoryId, topicId: topicId);
    final all =
    await service.getQuestions(categoryId: categoryId, topicId: topicId);
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color),
                  child: const Text('Back to Topics'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
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
    final user = context.watch<AuthProvider>().user;

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
                          'Hi, ${user?.username ?? 'Hero'} 👋',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const Text(
                          'What will you learn today?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
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
                                        style: TextStyle(
                                            color: AppColors.wrong)),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF9C93FF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐',
                          style: TextStyle(fontSize: 28)),
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

            // Categories
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
                        padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: topics.length,
                          itemBuilder: (context, tIndex) {
                            final topic = topics[tIndex];
                            return FutureBuilder<bool>(
                              future: _isTopicCompleted(
                                user,
                                cat['categoryId'] as String,
                                topic['topicId']!,
                              ),
                              builder: (context, snap) {
                                final done = snap.data ?? false;
                                return GestureDetector(
                                  onTap: () => _openQuiz(
                                    context,
                                    categoryId:
                                    cat['categoryId'] as String,
                                    categoryName: cat['title'] as String,
                                    topicId: topic['topicId']!,
                                    topicName: topic['name']!,
                                    color: color,
                                  ),
                                  child: Container(
                                    width: 88,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    decoration: BoxDecoration(
                                      color: done
                                          ? color.withOpacity(0.15)
                                          : Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                      border: Border.all(
                                        color: done
                                            ? color
                                            : const Color(0xFFE5E7EB),
                                        width: done ? 2 : 1,
                                      ),
                                      boxShadow: done
                                          ? null
                                          : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.04),
                                          blurRadius: 8,
                                          offset:
                                          const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            Text(topic['emoji']!,
                                                style: const TextStyle(
                                                    fontSize: 26)),
                                            if (done)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 9),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Text(
                                            topic['name']!,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: done
                                                  ? color
                                                  : AppColors.textPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                childCount: _categories.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}