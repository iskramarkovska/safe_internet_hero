import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/questions_service.dart';
import 'notifications_screen.dart';
import 'quiz_screen.dart';
import 'admin_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Privacy',
      'categoryId': 'privacy',
      'color': const Color(0xFF7C4DFF),
      'topics': [
        {'name': 'Personal Info', 'emoji': '🔒', 'topicId': 'personal_info'},
        {'name': 'Sharing Online', 'emoji': '📤', 'topicId': 'sharing_online'},
        {'name': 'Digital Footprint', 'emoji': '👣', 'topicId': 'digital_footprint'},
        {'name': 'App Permissions', 'emoji': '📱', 'topicId': 'app_permissions'},
      ],
    },
    {
      'title': 'Passwords',
      'categoryId': 'passwords',
      'color': const Color(0xFF00BCD4),
      'topics': [
        {'name': 'Strong Passwords', 'emoji': '🔐', 'topicId': 'strong_passwords'},
        {'name': 'Two Factor Auth', 'emoji': '🗝️', 'topicId': 'two_factor_auth'},
        {'name': 'Password Safety', 'emoji': '🛡️', 'topicId': 'password_safety'},
        {'name': 'Password Manager', 'emoji': '💾', 'topicId': 'password_manager'},
      ],
    },
    {
      'title': 'Cyberbullying',
      'categoryId': 'cyberbullying',
      'color': const Color(0xFFFF5252),
      'topics': [
        {'name': 'Spot Bullying', 'emoji': '💙', 'topicId': 'spot_bullying'},
        {'name': 'Be an Upstander', 'emoji': '✊', 'topicId': 'be_an_upstander'},
        {'name': 'Report & Block', 'emoji': '🚫', 'topicId': 'report_block'},
        {'name': 'Cyber Law', 'emoji': '⚖️', 'topicId': 'cyber_law'},
      ],
    },
    {
      'title': 'Social Media',
      'categoryId': 'social_media',
      'color': const Color(0xFFFFD740),
      'topics': [
        {'name': 'Privacy Settings', 'emoji': '📸', 'topicId': 'privacy_settings'},
        {'name': 'Strangers Online', 'emoji': '👤', 'topicId': 'strangers_online'},
        {'name': 'Geo Tagging', 'emoji': '📍', 'topicId': 'geo_tagging'},
        {'name': 'Screen Time', 'emoji': '⏱️', 'topicId': 'screen_time'},
      ],
    },
    {
      'title': 'Phishing',
      'categoryId': 'phishing',
      'color': const Color(0xFFFF6D00),
      'topics': [
        {'name': 'Spot Scams', 'emoji': '🎣', 'topicId': 'spot_scams'},
        {'name': 'Fake Links', 'emoji': '🔗', 'topicId': 'fake_links'},
        {'name': 'Email Safety', 'emoji': '📧', 'topicId': 'email_safety'},
        {'name': 'Spear Phishing', 'emoji': '🎯', 'topicId': 'spear_phishing'},
      ],
    },
  ];

  Future<bool> _isTopicCompleted({
    required UserModel? user,
    required String categoryId,
    required String topicId,
  }) async {
    if (user == null) return false;
    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
      categoryId: categoryId,
      topicId: topicId,
    );
    if (total == 0) return false;
    final allQuestions = await service.getQuestions(
      categoryId: categoryId,
      topicId: topicId,
    );
    final answered = allQuestions
        .where((q) => user.answeredQuestions.contains(q.id))
        .length;
    return answered >= total;
  }

  Future<void> _handleTopicTap({
    required BuildContext context,
    required String categoryId,
    required String categoryName,
    required String topicId,
    required String topicName,
    required Color color,
  }) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final service = QuestionService();
    final total = await service.getTotalQuestionsCount(
      categoryId: categoryId,
      topicId: topicId,
    );
    final allQuestions = await service.getQuestions(
      categoryId: categoryId,
      topicId: topicId,
    );
    final answeredInTopic = allQuestions
        .where((q) => user.answeredQuestions.contains(q.id))
        .length;

    if (total > 0 && answeredInTopic >= total) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              const Text(
                'Great job!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ve completed all questions in $topicName!',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$answeredInTopic/$total questions answered correctly',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Topics',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.username ?? 'Hero'}! 👋',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const Text(
                        'Topics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white70),
                        onPressed: () {},
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            ),
                          ),
                          if (user != null && user.friendRequests.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${user.friendRequests.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (user?.isAdmin == true)
                        IconButton(
                          icon: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Color(0xFFFFD700)),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AdminScreen()),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              title: const Text(
                                'Log out?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Are you sure you want to log out?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text(
                                    'Log out',
                                    style: TextStyle(color: Colors.red),
                                  ),
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

            // Stars banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
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
                        const Text(
                          'Your stars',
                          style: TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                        Text(
                          '${user?.totalStars ?? 0} stars earned',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black45,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            // Categories list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = category['color'] as Color;
                  final topics =
                  category['topics'] as List<Map<String, String>>;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    categoryId:
                                    category['categoryId'] as String,
                                    categoryName:
                                    category['title'] as String,
                                    topicId: '',
                                    topicName:
                                    category['title'] as String,
                                    color: color,
                                  ),
                                ),
                              ),
                              child: Text(
                                'SEE ALL',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Topic cards horizontal scroll
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: topics.length,
                          itemBuilder: (context, tIndex) {
                            final topic = topics[tIndex];
                            return FutureBuilder<bool>(
                              future: _isTopicCompleted(
                                user: user,
                                categoryId: category['categoryId'] as String,
                                topicId: topic['topicId']!,
                              ),
                              builder: (context, snapshot) {
                                final isCompleted = snapshot.data ?? false;
                                return GestureDetector(
                                  onTap: () => _handleTopicTap(
                                    context: context,
                                    categoryId:
                                    category['categoryId'] as String,
                                    categoryName:
                                    category['title'] as String,
                                    topicId: topic['topicId']!,
                                    topicName: topic['name']!,
                                    color: color,
                                  ),
                                  child: Container(
                                    width: 90,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? color.withOpacity(0.3)
                                          : color.withOpacity(0.15),
                                      borderRadius:
                                      BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isCompleted
                                            ? color
                                            : color.withOpacity(0.4),
                                        width: isCompleted ? 2 : 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          children: [
                                            Text(
                                              topic['emoji']!,
                                              style: const TextStyle(
                                                  fontSize: 28),
                                            ),
                                            if (isCompleted)
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                child: Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 10,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          topic['name']!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}