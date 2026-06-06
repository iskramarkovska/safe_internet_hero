import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final friendService = FriendService();
    final desktop = isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      // Back arrow hidden on desktop (browser back handles it)
                      if (!desktop)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: AppColors.textPrimary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Trailing spacer balances the back arrow to keep the
                      // title centered — only needed when the arrow is shown.
                      if (!desktop) const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
                child: user == null || user.friendRequests.isEmpty
                    ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: AppColors.teal, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Friend requests will appear here',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: user.friendRequests.length,
              itemBuilder: (context, index) {
                final fromId = user.friendRequests[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(fromId)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final username = data?['username'] ?? 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppColors.teal.withValues(alpha: 0.15),
                            child: Text(
                              username[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.teal,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Sent you a friend request',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_rounded,
                                color: AppColors.correct, size: 28),
                            onPressed: () async {
                              await friendService.acceptFriendRequest(
                                  user.id, fromId);
                              await auth.refreshUser();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'You and $username are now friends!'),
                                  backgroundColor: AppColors.correct,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded,
                                color: AppColors.wrong, size: 28),
                            onPressed: () async {
                              await friendService.declineFriendRequest(
                                  user.id, fromId);
                              await auth.refreshUser();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}
