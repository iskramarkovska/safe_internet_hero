import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/friend_service.dart';
import '../../widgets/app_avatar.dart';

class AllFriendsScreen extends StatefulWidget {
  final UserModel user;
  final int initialTab;
  const AllFriendsScreen({super.key, required this.user, this.initialTab = 0});

  @override
  State<AllFriendsScreen> createState() => _AllFriendsScreenState();
}

class _AllFriendsScreenState extends State<AllFriendsScreen>
    with SingleTickerProviderStateMixin {
  final _friendService = FriendService();
  late final TabController _tabs;

  List<UserModel> _friends = [];
  List<UserModel> _requesters = [];
  bool _loading = true;
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this,
        initialIndex: widget.initialTab);
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .snapshots()
        .listen(_onSnapshot);
  }

  void _onSnapshot(DocumentSnapshot snap) {
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    _loadFriends(List<String>.from(data['friends'] ?? []));
    _loadRequesters(List<String>.from(data['friendRequests'] ?? []));
  }

  Future<void> _loadFriends(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() { _friends = []; _loading = false; });
      return;
    }
    final users = await _friendService.getUsersByIds(ids);
    if (!mounted) return;
    setState(() { _friends = users; _loading = false; });
  }

  Future<void> _loadRequesters(List<String> ids) async {
    if (ids.isEmpty) {
      if (mounted) setState(() => _requesters = []);
      return;
    }
    final users = await _friendService.getUsersByIds(ids);
    if (!mounted) return;
    setState(() => _requesters = users);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? widget.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          size: 16, color: AppColors.textPrimary),
                    ),
                  ),
                  const Spacer(),
                  _TopStat(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.orange,
                      value: '${user.currentStreak}'),
                  const SizedBox(width: 20),
                  _TopStat(
                      icon: Icons.monetization_on_rounded,
                      color: AppColors.gold,
                      value: '${user.coins}'),
                  const SizedBox(width: 20),
                  _TopStat(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFE57373),
                      value: '${user.totalStars}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'All friends',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabs,
                labelColor: AppColors.blue,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    letterSpacing: 0.5),
                unselectedLabelStyle: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
                indicatorColor: AppColors.blue,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: AppColors.border,
                tabs: [
                  Tab(text: 'FOLLOWING (${_friends.length})'),
                  Tab(text: 'FOLLOWERS (${_requesters.length})'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.blue, strokeWidth: 2))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _FollowingTab(
                          friends: _friends,
                          currentUserId: widget.user.id,
                          friendService: _friendService,
                          onRemoved: (id) {
                            context.read<AuthProvider>().refreshUser();
                          },
                        ),
                        _RequestsTab(
                          requesters: _requesters,
                          currentUserId: widget.user.id,
                          friendService: _friendService,
                          onChanged: () {
                            context.read<AuthProvider>().refreshUser();
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat chip in top bar ─────────────────────────────────────────────────────

class _TopStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _TopStat({required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ],
    );
  }
}

// ─── Following tab ────────────────────────────────────────────────────────────

class _FollowingTab extends StatelessWidget {
  final List<UserModel> friends;
  final String currentUserId;
  final FriendService friendService;
  final void Function(String removedId) onRemoved;

  const _FollowingTab({
    required this.friends,
    required this.currentUserId,
    required this.friendService,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.people_outline_rounded,
                    color: AppColors.blue, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('No friends yet',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Add friends to compete together!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: friends.asMap().entries.map((e) {
              final friend = e.value;
              final isLast = e.key == friends.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AppAvatar(name: friend.username, size: 44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend.username,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text('${friend.totalStars} XP',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _confirmRemove(context, friend),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.redLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Remove',
                                style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                        height: 1,
                        color: AppColors.border,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, UserModel friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: const BoxDecoration(
                    color: AppColors.redLight,
                    shape: BoxShape.circle),
                child: const Icon(Icons.person_remove_rounded,
                    color: AppColors.red, size: 26),
              ),
              const SizedBox(height: 12),
              Text('Remove ${friend.username}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'They will no longer be on your friends list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Remove',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await friendService.removeFriend(currentUserId, friend.id);
      onRemoved(friend.id);
    }
  }
}

// ─── Requests tab ─────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final List<UserModel> requesters;
  final String currentUserId;
  final FriendService friendService;
  final VoidCallback onChanged;

  const _RequestsTab({
    required this.requesters,
    required this.currentUserId,
    required this.friendService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (requesters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.person_add_outlined,
                    color: AppColors.blue, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('No pending requests',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Friend requests will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: requesters.asMap().entries.map((e) {
              final r = e.value;
              final isLast = e.key == requesters.length - 1;
              return Column(
                children: [
                  _FriendRequestRow(
                    requester: r,
                    currentUserId: currentUserId,
                    friendService: friendService,
                    onChanged: onChanged,
                  ),
                  if (!isLast)
                    Container(
                        height: 1,
                        color: AppColors.border,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Friend request row ───────────────────────────────────────────────────────

class _FriendRequestRow extends StatelessWidget {
  final UserModel requester;
  final String currentUserId;
  final FriendService friendService;
  final VoidCallback onChanged;

  const _FriendRequestRow({
    required this.requester,
    required this.currentUserId,
    required this.friendService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppAvatar(name: requester.username, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(requester.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text('${requester.totalStars} XP',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await friendService.acceptFriendRequest(
                  currentUserId, requester.id);
              onChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Accept',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Decline',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
