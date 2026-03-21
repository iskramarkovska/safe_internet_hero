import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/friend_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final friendService = FriendService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: user == null || user.friendRequests.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔔', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Friend requests will appear here',
              style: TextStyle(color: Colors.white54),
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
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final data =
              snapshot.data!.data() as Map<String, dynamic>?;
              final username = data?['username'] ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor:
                      const Color(0xFF00D4FF).withOpacity(0.2),
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Sent you a friend request',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Buttons
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: Colors.green, size: 28),
                      onPressed: () async {
                        await friendService.acceptFriendRequest(
                            user.id, fromId);
                        await auth.refreshUser();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'You and $username are now friends!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Colors.red, size: 28),
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
    );
  }
}