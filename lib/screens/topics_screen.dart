import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final categories = [
      {
        'title': 'Privacy',
        'color': const Color(0xFF7C4DFF),
        'topics': [
          {'name': 'Personal Info', 'emoji': '🔒'},
          {'name': 'Sharing Online', 'emoji': '📤'},
          {'name': 'Digital Footprint', 'emoji': '👣'},
          {'name': 'App Permissions', 'emoji': '📱'},
        ],
      },
      {
        'title': 'Passwords',
        'color': const Color(0xFF00BCD4),
        'topics': [
          {'name': 'Strong Passwords', 'emoji': '🔐'},
          {'name': 'Two Factor Auth', 'emoji': '🗝️'},
          {'name': 'Password Safety', 'emoji': '🛡️'},
          {'name': 'Password Manager', 'emoji': '💾'},
        ],
      },
      {
        'title': 'Cyberbullying',
        'color': const Color(0xFFFF5252),
        'topics': [
          {'name': 'Spot Bullying', 'emoji': '💙'},
          {'name': 'Be an Upstander', 'emoji': '✊'},
          {'name': 'Report & Block', 'emoji': '🚫'},
          {'name': 'Cyber Law', 'emoji': '⚖️'},
        ],
      },
      {
        'title': 'Social Media',
        'color': const Color(0xFFFFD740),
        'topics': [
          {'name': 'Privacy Settings', 'emoji': '📸'},
          {'name': 'Strangers Online', 'emoji': '👤'},
          {'name': 'Geo Tagging', 'emoji': '📍'},
          {'name': 'Screen Time', 'emoji': '⏱️'},
        ],
      },
      {
        'title': 'Phishing',
        'color': const Color(0xFFFF6D00),
        'topics': [
          {'name': 'Spot Scams', 'emoji': '🎣'},
          {'name': 'Fake Links', 'emoji': '🔗'},
          {'name': 'Email Safety', 'emoji': '📧'},
          {'name': 'Spear Phishing', 'emoji': '🎯'},
        ],
      },
    ];

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
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white70),
                            onPressed: () {},
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            color: Colors.black54,
                            fontSize: 12,
                          ),
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
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.black45, size: 16),
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
                              onPressed: () {},
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: topics.length,
                          itemBuilder: (context, tIndex) {
                            final topic = topics[tIndex];
                            return GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: color.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      topic['emoji']!,
                                      style: const TextStyle(fontSize: 28),
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