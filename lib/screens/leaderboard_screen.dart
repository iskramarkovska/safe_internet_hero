import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

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
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            // Top 3 podium
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('totalStars', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final top3 = snapshot.data!.docs;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top3.length > 1)
                        _podiumItem(top3[1], '🥈', 2, 80, currentUser),
                      if (top3.isNotEmpty)
                        _podiumItem(top3[0], '🥇', 1, 110, currentUser),
                      if (top3.length > 2)
                        _podiumItem(top3[2], '🥉', 3, 60, currentUser),
                    ],
                  ),
                );
              },
            ),

            // Full list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('totalStars', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data =
                      users[index].data() as Map<String, dynamic>;
                      final isCurrentUser =
                          data['uid'] == currentUser?.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? const Color(0xFF00D4FF).withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrentUser
                                ? const Color(0xFF00D4FF)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank
                            SizedBox(
                              width: 32,
                              child: Text(
                                index == 0
                                    ? '🥇'
                                    : index == 1
                                    ? '🥈'
                                    : index == 2
                                    ? '🥉'
                                    : '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: index < 3 ? 20 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                              const Color(0xFF00D4FF).withOpacity(0.2),
                              child: Text(
                                (data['username'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['username'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? const Color(0xFF00D4FF)
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    data['ageGroup'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stars
                            Row(
                              children: [
                                const Text('⭐',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Text(
                                  '${data['totalStars'] ?? 0}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(DocumentSnapshot doc, String medal, int rank,
      double height, UserModel? currentUser) {
    final data = doc.data() as Map<String, dynamic>;
    final isCurrentUser = data['uid'] == currentUser?.id;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          (data['username'] ?? '?')[0].toUpperCase(),
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0xFF00D4FF).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF00D4FF)
                  : Colors.white24,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['username'] ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '⭐ ${data['totalStars'] ?? 0}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}