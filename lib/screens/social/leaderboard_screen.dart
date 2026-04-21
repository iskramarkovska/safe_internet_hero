import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/skeleton_loader.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Teal header
            Container(
              color: AppColors.teal,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 Leaderboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'See how you rank against others',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Podium — top 3
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('totalStars', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const LeaderboardPodiumSkeleton();
                }
                final top3 = snap.data!.docs;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.teal.withOpacity(0.08),
                        AppColors.teal.withOpacity(0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.teal.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (top3.length > 1)
                        _podiumItem(top3[1], '🥈', 80, currentUser),
                      if (top3.isNotEmpty)
                        _podiumItem(top3[0], '🥇', 108, currentUser),
                      if (top3.length > 2)
                        _podiumItem(top3[2], '🥉', 60, currentUser),
                    ],
                  ),
                ).animate().fadeIn(duration: const Duration(milliseconds: 400));
              },
            ),

            const SizedBox(height: 16),

            // Full ranked list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('totalStars', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children:
                          List.generate(8, (_) => const LeaderboardRowSkeleton()),
                    );
                  }
                  final users = snap.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data =
                          users[index].data() as Map<String, dynamic>;
                      final isMe = data['uid'] == currentUser?.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.teal.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe
                                ? AppColors.teal
                                : const Color(0xFFE5E7EB),
                            width: isMe ? 2 : 1,
                          ),
                          boxShadow: isMe
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
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
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: index < 3 ? 20 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  AppColors.teal.withOpacity(0.12),
                              child: Text(
                                (data['username'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(
                                  color: isMe
                                      ? AppColors.teal
                                      : AppColors.darkTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['username'] ?? 'Unknown',
                                style: TextStyle(
                                  color: isMe
                                      ? AppColors.teal
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Text('⭐',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${data['totalStars'] ?? 0}',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                          .animate(
                              delay: Duration(
                                  milliseconds: (index * 40).clamp(0, 400)))
                          .fadeIn(duration: const Duration(milliseconds: 300))
                          .slideX(
                              begin: 0.05,
                              end: 0,
                              duration: const Duration(milliseconds: 300));
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

  Widget _podiumItem(DocumentSnapshot doc, String medal, double height,
      UserModel? currentUser) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['uid'] == currentUser?.id;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.teal.withOpacity(0.12),
          child: Text(
            (data['username'] ?? '?')[0].toUpperCase(),
            style: TextStyle(
                color: isMe ? AppColors.teal : AppColors.darkTeal,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(medal, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Container(
          width: 76,
          height: height,
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.teal.withOpacity(0.2)
                : const Color(0xFFE5E7EB),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: isMe ? AppColors.teal : const Color(0xFFD1D5DB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['username'] ?? '?',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '⭐ ${data['totalStars'] ?? 0}',
                style:
                    const TextStyle(color: AppColors.gold, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
