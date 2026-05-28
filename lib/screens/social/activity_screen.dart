import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_page_route.dart';
import '../../providers/auth_provider.dart';
import '../../models/activity_model.dart';
import '../../services/friend_service.dart';
import '../../models/user_model.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../auth/splash_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoadingSearch = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoadingSearch = true);
    final results = await _friendService.searchUsers(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isLoadingSearch = false;
    });
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
          // ── Top bar + gradient header with tabs ───────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(
                  stars: user?.totalStars ?? 0,
                  streak: user?.currentStreak ?? 0,
                  coins: user?.coins ?? 0,
                ),
                Container(height: 1, color: AppColors.border),
                Container(
                  width: double.infinity,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activity',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'See what your friends are up to',
                              style: GoogleFonts.nunito(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isGuest) ...[
                        const SizedBox(height: 8),
                        TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor:
                              Colors.white.withValues(alpha: 0.6),
                          labelStyle: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800, fontSize: 14),
                          unselectedLabelStyle: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Friends'),
                            Tab(text: 'Find Friends'),
                          ],
                        ),
                      ] else
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
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

          // ── Logged-in tabbed content ───────────────────────────────────────
          if (!isGuest)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 0: Friends Activity ──────────────────────────────
                  _FriendsTab(
                    user: user,
                    friendService: _friendService,
                    auth: auth,
                    timeAgo: _timeAgo,
                    activityIcon: _activityIcon,
                    activityColor: _activityColor,
                    onFindFriends: () => _tabController.animateTo(1),
                  ),

                  // ── Tab 1: Find Friends ──────────────────────────────────
                  _FindFriendsTab(
                    currentUser: user,
                    friendService: _friendService,
                    searchController: _searchController,
                    searchResults: _searchResults,
                    isLoadingSearch: _isLoadingSearch,
                    onSearch: _search,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Friends Activity Tab ─────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  final UserModel? user;
  final FriendService friendService;
  final AuthProvider auth;
  final String Function(DateTime) timeAgo;
  final IconData Function(ActivityType) activityIcon;
  final Color Function(ActivityType) activityColor;
  final VoidCallback onFindFriends;

  const _FriendsTab({
    required this.user,
    required this.friendService,
    required this.auth,
    required this.timeAgo,
    required this.activityIcon,
    required this.activityColor,
    required this.onFindFriends,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.blue));
    }

    return Column(
      children: [
        // Pending friend requests
        _PendingRequestsSection(
          currentUser: user!,
          friendService: friendService,
          onChanged: auth.refreshUser,
        ),

        // Activity feed
        Expanded(
          child: user!.friends.isEmpty
              ? _buildNoFriendsState()
              : StreamBuilder<List<ActivityModel>>(
                  stream: friendService.getFriendsActivity(user!.friends),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildError();
                    }
                    if (!snapshot.hasData) {
                      return _buildFeedSkeleton();
                    }
                    if (snapshot.data!.isEmpty) {
                      return _buildEmptyFeed();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => _ActivityItem(
                        activity: snapshot.data![index],
                        timeAgo: timeAgo,
                        activityIcon: activityIcon,
                        activityColor: activityColor,
                      )
                          .animate(
                              delay: Duration(
                                  milliseconds: (index * 40).clamp(0, 300)))
                          .fadeIn(duration: const Duration(milliseconds: 280))
                          .slideY(
                              begin: 0.05,
                              end: 0,
                              duration: const Duration(milliseconds: 280)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNoFriendsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: AppColors.blue, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'No friends yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find friends to see their learning\nactivity here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Find Friends',
              variant: AppButtonVariant.primary,
              icon: Icons.person_search_rounded,
              onTap: onFindFriends,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.hourglass_empty_rounded,
                size: 56, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'No activity yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your friends haven\'t done any quizzes yet.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return const Center(
      child: Text(
        'Could not load activity',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildFeedSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: const Duration(milliseconds: 1000)),
      ),
    );
  }
}

// ─── Activity item ────────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final ActivityModel activity;
  final String Function(DateTime) timeAgo;
  final IconData Function(ActivityType) activityIcon;
  final Color Function(ActivityType) activityColor;

  const _ActivityItem({
    required this.activity,
    required this.timeAgo,
    required this.activityIcon,
    required this.activityColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activityColor(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(activityIcon(activity.type), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.username,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
                Text(
                  activity.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                Text(
                  activity.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
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
                          color: AppColors.gold, fontWeight: FontWeight.w800)),
                  const Icon(Icons.star_rounded,
                      color: AppColors.gold, size: 14),
                ],
              ),
              Text(
                timeAgo(activity.createdAt),
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Find Friends Tab ─────────────────────────────────────────────────────────

class _FindFriendsTab extends StatelessWidget {
  final UserModel? currentUser;
  final FriendService friendService;
  final TextEditingController searchController;
  final List<UserModel> searchResults;
  final bool isLoadingSearch;
  final Future<void> Function(String) onSearch;

  const _FindFriendsTab({
    required this.currentUser,
    required this.friendService,
    required this.searchController,
    required this.searchResults,
    required this.isLoadingSearch,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle:
                    GoogleFonts.nunito(color: AppColors.textLight),
                prefixIcon: const Icon(Icons.person_search_rounded,
                    color: AppColors.blue, size: 22),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: isLoadingSearch
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue))
              : searchController.text.isEmpty
                  ? _buildSearchPrompt()
                  : searchResults.isEmpty
                      ? _buildNoResults()
                      : _buildResults(context),
        ),
      ],
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_rounded, size: 56, color: AppColors.textLight),
            SizedBox(height: 16),
            Text(
              'Find your friends',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Search by username to add friends\nand compete together!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search_off_rounded,
              color: AppColors.textLight, size: 48),
          SizedBox(height: 16),
          Text('No users found',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          SizedBox(height: 8),
          Text(
            'Try a different username',
            style: TextStyle(
                color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final filtered =
        searchResults.where((r) => r.id != currentUser?.id).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final result = filtered[index];
        final isFriend = currentUser?.friends.contains(result.id) ?? false;
        final isRequested = result.friendRequests.contains(currentUser?.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              AppAvatar(name: result.username, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.username,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                    Text(
                      '${result.totalStars} ⭐',
                      style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (isFriend)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Friends',
                      style: TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                )
              else if (isRequested)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Requested',
                      style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                )
              else
                AppButton(
                  label: 'Add',
                  variant: AppButtonVariant.primary,
                  onTap: currentUser == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await friendService.sendFriendRequest(
                              currentUser!.id, result.id);
                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Friend request sent!'),
                                backgroundColor: AppColors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                          await onSearch(searchController.text);
                        },
                ),
            ],
          ),
        )
            .animate(
                delay: Duration(milliseconds: (index * 50).clamp(0, 250)))
            .fadeIn(duration: const Duration(milliseconds: 280))
            .slideX(
                begin: 0.05,
                end: 0,
                duration: const Duration(milliseconds: 280));
      },
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  _loadRequesters(_requesters
                      .where((u) => u.id != r.id)
                      .map((u) => u.id)
                      .toList());
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
          AppAvatar(name: requester.username, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              requester.username,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
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
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
