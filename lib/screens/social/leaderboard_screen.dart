import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import '../auth/splash_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<int>? _rankFuture;
  int? _lastStars;

  Future<int> _computeUserRank(int userStars) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('totalStars', isGreaterThan: userStars)
          .count()
          .get();
      return (snap.count ?? 0) + 1;
    } catch (_) {
      return 0;
    }
  }

  void _maybeRefreshRank(int stars) {
    if (stars != _lastStars) {
      _lastStars = stars;
      setState(() {
        _rankFuture = _computeUserRank(stars);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;
    final isGuest = auth.isGuest;
    final stars = currentUser?.totalStars ?? 0;
    final streak = currentUser?.currentStreak ?? 0;
    final coins = currentUser?.coins ?? 0;

    if (!isGuest && currentUser != null) {
      _maybeRefreshRank(stars);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(stars: stars, streak: streak, coins: coins),
                Container(height: 1, color: AppColors.border),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                      Text(
                        'Leaderboard',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'See how you rank against other heroes',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isGuest)
            Expanded(
              child: GuestLockedState(
                icon: Icons.leaderboard_rounded,
                title: 'Compete with the world',
                subtitle:
                    'Create a free account to appear on the leaderboard and track your rank against other internet safety heroes.',
                onGetStarted: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                ),
              ),
            ),

          if (!isGuest)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // ── Podium ─────────────────────────────────────────────
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
                        final docs = snap.data!.docs;
                        return _Podium(docs: docs, currentUser: currentUser)
                            .animate()
                            .fadeIn(duration: const Duration(milliseconds: 500))
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Your Rank card ─────────────────────────────────────
                    if (currentUser != null)
                      FutureBuilder<int>(
                        future: _rankFuture,
                        builder: (context, snap) {
                          return _YourRankCard(
                            user: currentUser,
                            rank: snap.data,
                            loading: snap.connectionState ==
                                ConnectionState.waiting,
                          )
                              .animate()
                              .fadeIn(
                                  delay: const Duration(milliseconds: 200),
                                  duration: const Duration(milliseconds: 400))
                              .slideY(
                                  begin: 0.08,
                                  end: 0,
                                  duration: const Duration(milliseconds: 350));
                        },
                      ),

                    const SizedBox(height: 20),

                    // ── Top 50 list ────────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Top 50',
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('totalStars', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return Column(
                            children: List.generate(
                                8, (_) => const LeaderboardRowSkeleton()),
                          );
                        }
                        final users = snap.data!.docs;
                        return Column(
                          children: users.asMap().entries.map((e) {
                            final index = e.key;
                            final data =
                                e.value.data() as Map<String, dynamic>;
                            final isMe = data['uid'] == currentUser?.id;

                            return _LeaderboardRow(
                              rank: index + 1,
                              username: data['username'] ?? 'Unknown',
                              stars: data['totalStars'] ?? 0,
                              isMe: isMe,
                            )
                                .animate(
                                    delay: Duration(
                                        milliseconds:
                                            (index * 40).clamp(0, 400)))
                                .fadeIn(
                                    duration:
                                        const Duration(milliseconds: 300))
                                .slideX(
                                    begin: 0.05,
                                    end: 0,
                                    duration:
                                        const Duration(milliseconds: 300));
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Your Rank card ───────────────────────────────────────────────────────────

class _YourRankCard extends StatelessWidget {
  final UserModel user;
  final int? rank;
  final bool loading;

  const _YourRankCard({
    required this.user,
    required this.rank,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF5AB4F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(
            name: user.username,
            size: 44,
            borderColor: Colors.white,
            borderWidth: 2.5,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${user.totalStars} stars',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Column(
                    children: [
                      Text(
                        rank != null && rank! > 0 ? '#$rank' : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Your Rank',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Podium ───────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<DocumentSnapshot> docs;
  final UserModel? currentUser;

  const _Podium({required this.docs, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Text(
            'Top Performers',
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (docs.length > 1)
                _PodiumSlot(
                  doc: docs[1],
                  rank: 2,
                  pillarHeight: 80,
                  color: const Color(0xFFC0C0C0),
                  shadowColor: const Color(0xFF9E9E9E),
                  isMe: (docs[1].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 80),
              if (docs.isNotEmpty)
                _PodiumSlot(
                  doc: docs[0],
                  rank: 1,
                  pillarHeight: 110,
                  color: AppColors.gold,
                  shadowColor: AppColors.goldDark,
                  isMe: (docs[0].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 80),
              if (docs.length > 2)
                _PodiumSlot(
                  doc: docs[2],
                  rank: 3,
                  pillarHeight: 55,
                  color: const Color(0xFFCD7F32),
                  shadowColor: const Color(0xFF9E5B20),
                  isMe: (docs[2].data() as Map)['uid'] == currentUser?.id,
                )
              else
                const SizedBox(width: 80),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final DocumentSnapshot doc;
  final int rank;
  final double pillarHeight;
  final Color color;
  final Color shadowColor;
  final bool isMe;

  const _PodiumSlot({
    required this.doc,
    required this.rank,
    required this.pillarHeight,
    required this.color,
    required this.shadowColor,
    required this.isMe,
  });

  static const _crownIcons = [
    Icons.emoji_events_rounded,
    Icons.military_tech_rounded,
    Icons.workspace_premium_rounded,
  ];
  static const _crownSizes = [26.0, 22.0, 20.0];

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final username = data['username'] ?? '?';
    final stars = data['totalStars'] ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(_crownIcons[rank - 1], color: color, size: _crownSizes[rank - 1]),
        const SizedBox(height: 4),

        AppAvatar(
          name: username,
          size: 46,
          borderColor: isMe ? AppColors.blue : color,
          borderWidth: isMe ? 3 : 2.5,
        ),

        const SizedBox(height: 6),

        SizedBox(
          width: 80,
          child: Text(
            username,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: isMe ? AppColors.blue : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Container(
          width: 72,
          height: pillarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, shadowColor],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.6),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.white, size: 11),
                  const SizedBox(width: 2),
                  Text(
                    '$stars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── List row ─────────────────────────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String username;
  final int stars;
  final bool isMe;

  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.stars,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.blueLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.blue : AppColors.border,
          width: isMe ? 2 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Icon(
                    [
                      Icons.emoji_events_rounded,
                      Icons.military_tech_rounded,
                      Icons.workspace_premium_rounded,
                    ][rank - 1],
                    color: [
                      AppColors.gold,
                      const Color(0xFFC0C0C0),
                      const Color(0xFFCD7F32),
                    ][rank - 1],
                    size: 22,
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          AppAvatar(name: username, size: 38),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: isMe ? AppColors.blue : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: AppColors.gold, size: 17),
              const SizedBox(width: 3),
              Text(
                '$stars',
                style: GoogleFonts.nunito(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
