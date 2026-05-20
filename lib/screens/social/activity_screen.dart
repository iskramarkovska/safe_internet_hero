import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_page_route.dart';
import '../../providers/auth_provider.dart';
import '../../models/activity_model.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _friendService.searchUsers(query);
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _activityIcon(ActivityType type) => switch (type) {
        ActivityType.quizCompleted => Icons.quiz_rounded,
        ActivityType.topicCompleted => Icons.check_circle_rounded,
        ActivityType.badgeEarned => Icons.emoji_events_rounded,
      };

  Color _activityColor(ActivityType type) => switch (type) {
        ActivityType.quizCompleted => AppColors.blue,
        ActivityType.topicCompleted => AppColors.green,
        ActivityType.badgeEarned => AppColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.blue, Color(0xFF5AB4F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!isGuest)
                        IconButton(
                          icon: Icon(
                            _isSearching
                                ? Icons.close
                                : Icons.person_search_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchController.clear();
                                _searchResults = [];
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (!isGuest && _isSearching) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      onChanged: _search,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by username...',
                        hintStyle: const TextStyle(color: Colors.white60),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Guest locked state ─────────────────────────────────────────────
          if (isGuest)
            Expanded(
              child: GuestLockedState(
                icon: Icons.people_rounded,
                title: 'See your friends\' activity',
                subtitle:
                    'Create a free account to add friends and follow their internet safety learning journey.',
                onGetStarted: () =>
                    Navigator.of(context).pushAndRemoveUntil(
                  AppPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                ),
              ),
            ),

          // ── Logged-in content ──────────────────────────────────────────────
          if (!isGuest) ...[
            // Incoming friend requests
            if (user != null)
              _PendingRequestsSection(
                currentUser: user,
                friendService: _friendService,
                onChanged: () => auth.refreshUser(),
              ),

            // Search results
            if (_isSearching && _searchResults.isNotEmpty)
              _buildSearchResults(user),

            // Activity feed or empty state
            if (!_isSearching || _searchResults.isEmpty)
              Expanded(
                child: user == null || user.friends.isEmpty
                    ? _buildEmptyState()
                    : StreamBuilder<List<ActivityModel>>(
                        stream: _friendService
                            .getFriendsActivity(user.friends),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Could not load activity',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.blue),
                            );
                          }
                          if (snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) =>
                                _buildActivityItem(snapshot.data![index]),
                          );
                        },
                      ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(UserModel? currentUser) {
    final filtered =
        _searchResults.where((r) => r.id != currentUser?.id).toList();

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search_off_rounded,
                  color: AppColors.textLight, size: 40),
              SizedBox(height: 12),
              Text('No users found',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final result = filtered[index];
          final isFriend =
              currentUser?.friends.contains(result.id) ?? false;
          final isRequested =
              result.friendRequests.contains(currentUser?.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
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
                  backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                  child: Text(
                    result.username.isNotEmpty
                        ? result.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.username,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (isFriend)
                  const Text('✅ Friends',
                      style: TextStyle(
                          color: AppColors.correct,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
                else if (isRequested)
                  const Text('Requested',
                      style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))
                else
                  ElevatedButton(
                    onPressed: currentUser == null
                        ? null
                        : () async {
                            final messenger =
                                ScaffoldMessenger.of(context);
                            await _friendService.sendFriendRequest(
                                currentUser.id, result.id);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    const Text('Friend request sent!'),
                                backgroundColor: AppColors.correct,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ),
                            );
                            await _search(_searchController.text);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Add',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _activityColor(activity.type).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_activityIcon(activity.type),
                color: _activityColor(activity.type), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.username,
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  activity.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  activity.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('+${activity.starsEarned} ',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.star_rounded,
                      color: AppColors.gold, size: 14),
                ],
              ),
              Text(
                _timeAgo(activity.createdAt),
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No activity yet',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add friends to see their activity here',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isSearching = true),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Find Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pending friend requests ───────────────────────────────────────────────────

class _PendingRequestsSection extends StatefulWidget {
  final UserModel currentUser;
  final FriendService friendService;
  final VoidCallback onChanged;

  const _PendingRequestsSection({
    required this.currentUser,
    required this.friendService,
    required this.onChanged,
  });

  @override
  State<_PendingRequestsSection> createState() =>
      _PendingRequestsSectionState();
}

class _PendingRequestsSectionState extends State<_PendingRequestsSection> {
  List<UserModel> _requesters = [];
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe(widget.currentUser.id);
  }

  @override
  void didUpdateWidget(_PendingRequestsSection old) {
    super.didUpdateWidget(old);
    if (old.currentUser.id != widget.currentUser.id) {
      _subscription?.cancel();
      _subscribe(widget.currentUser.id);
    }
  }

  void _subscribe(String userId) {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(_onUserSnap);
  }

  void _onUserSnap(DocumentSnapshot snap) {
    if (!snap.exists) return;
    final ids = List<String>.from(
        (snap.data() as Map<String, dynamic>)['friendRequests'] ?? []);
    _loadRequesters(ids);
  }

  Future<void> _loadRequesters(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() => _requesters = []);
      return;
    }
    final users = await widget.friendService.getUsersByIds(ids);
    if (!mounted) return;
    setState(() => _requesters = users);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_requesters.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.blueLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_rounded,
                  color: AppColors.blue, size: 15),
              const SizedBox(width: 6),
              Text(
                'Friend Requests (${_requesters.length})',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._requesters.map((r) => _RequestTile(
                requester: r,
                currentUserId: widget.currentUser.id,
                friendService: widget.friendService,
                onChanged: () {
                  widget.onChanged();
                  _loadRequesters(
                      _requesters.where((u) => u.id != r.id).map((u) => u.id).toList());
                },
              )),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final UserModel requester;
  final String currentUserId;
  final FriendService friendService;
  final VoidCallback onChanged;

  const _RequestTile({
    required this.requester,
    required this.currentUserId,
    required this.friendService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blue.withValues(alpha: 0.15),
            child: Text(
              requester.username.isNotEmpty
                  ? requester.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              requester.username,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await friendService.acceptFriendRequest(
                  currentUserId, requester.id);
              onChanged();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              await friendService.declineFriendRequest(
                  currentUserId, requester.id);
              onChanged();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Decline',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
