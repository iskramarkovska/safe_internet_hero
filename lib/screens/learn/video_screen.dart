import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_service.dart';
import '../auth/splash_screen.dart';

class VideoScreen extends StatefulWidget {
  final LearningContentModel content;
  const VideoScreen({super.key, required this.content});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  static const _xp = 5;
  static const _ytRed = Color(0xFFFF0000);

  final _learningService = LearningService();

  bool _watchTriggered = false;
  bool _xpLoading = false;
  // null = not watched yet, 0 = already watched, >0 = just earned
  int? _xpEarned;

  String get _thumbUrl =>
      'https://img.youtube.com/vi/${widget.content.content.trim()}/maxresdefault.jpg';

  Future<void> _onWatch() async {
    await _launchVideo();
    if (!_watchTriggered) {
      _watchTriggered = true;
      await _awardXp();
    }
  }

  Future<void> _launchVideo() async {
    final videoId = widget.content.content.trim();
    final youtubeApp = Uri.parse('vnd.youtube:$videoId');
    final youtubeWeb =
        Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(youtubeApp)) {
      await launchUrl(youtubeApp);
    } else if (await canLaunchUrl(youtubeWeb)) {
      await launchUrl(youtubeWeb, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(youtubeWeb, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _awardXp() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    if (auth.isGuest) {
      setState(() => _xpEarned = -1); // sentinel for guest
      return;
    }

    final user = auth.user;
    if (user == null) return;

    setState(() => _xpLoading = true);
    try {
      final earned = await _learningService.markContentRead(
        userId: user.id,
        contentId: widget.content.id,
        xpToAward: _xp,
      );
      if (!mounted) return;
      setState(() {
        _xpEarned = earned;
        _xpLoading = false;
      });
      if (earned > 0) auth.refreshUser();
    } catch (_) {
      if (!mounted) return;
      setState(() => _xpLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.read<AuthProvider>().isGuest;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.content.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.border),

            // ── Body ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail with play overlay
                    GestureDetector(
                      onTap: _onWatch,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              _thumbUrl,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _VideoPlaceholder(),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 220,
                              color: Colors.black.withValues(alpha: 0.28),
                            ),
                          ),
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _ytRed,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 46),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.96, 0.96),
                          end: const Offset(1, 1),
                          duration: 350.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 300.ms),

                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded,
                              color: AppColors.textLight, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to watch on YouTube',
                            style: GoogleFonts.nunito(
                              color: AppColors.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // VIDEO badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _ytRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _ytRed.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.play_circle_rounded,
                            color: _ytRed, size: 12),
                        const SizedBox(width: 5),
                        Text('VIDEO',
                            style: GoogleFonts.nunito(
                              color: _ytRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            )),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      widget.content.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),

                    if (widget.content.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.content.description,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Watch button
                    _WatchButton(onTap: _onWatch),

                    const SizedBox(height: 16),

                    // XP result card — appears after watching
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      child: _watchTriggered
                          ? _XpResultCard(
                              isGuest: isGuest,
                              isLoading: _xpLoading,
                              xpEarned: _xpEarned,
                              onCreateAccount: () {
                                context.read<AuthProvider>().exitGuestMode();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  AppPageRoute(
                                      builder: (_) => const LandingScreen()),
                                  (r) => false,
                                );
                              },
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(
                                    begin: 0.1, end: 0, duration: 300.ms)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Watch button ─────────────────────────────────────────────────────────────

class _WatchButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WatchButton({required this.onTap});

  @override
  State<_WatchButton> createState() => _WatchButtonState();
}

class _WatchButtonState extends State<_WatchButton> {
  bool _pressed = false;

  static const _ytRed = Color(0xFFFF0000);
  static const _ytDark = Color(0xFFCC0000);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _ytDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const SizedBox.shrink(),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: double.infinity,
            margin: EdgeInsets.only(top: _pressed ? 4 : 0),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: _ytRed,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text('Watch on YouTube',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── XP result card ───────────────────────────────────────────────────────────

class _XpResultCard extends StatelessWidget {
  final bool isGuest;
  final bool isLoading;
  final int? xpEarned;
  final VoidCallback onCreateAccount;

  const _XpResultCard({
    required this.isGuest,
    required this.isLoading,
    required this.xpEarned,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return _GuestXpCard(onCreateAccount: onCreateAccount);
    }
    if (isLoading || xpEarned == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: AppColors.green, strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (xpEarned! == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.blueLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.blue.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Already watched — no extra XP.',
                style: GoogleFonts.nunito(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        const Icon(Icons.star_rounded, color: AppColors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text('+${xpEarned!} XP earned for watching!',
              style: GoogleFonts.nunito(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ),
      ]),
    );
  }
}

class _GuestXpCard extends StatelessWidget {
  final VoidCallback onCreateAccount;
  const _GuestXpCard({required this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.blue.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        const Icon(Icons.lock_open_rounded, color: AppColors.blue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Create a free account to earn XP for watching.',
              style: GoogleFonts.nunito(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.4)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onCreateAccount,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Join',
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

// ─── Video placeholder ────────────────────────────────────────────────────────

class _VideoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFFF6060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Center(
        child: Icon(Icons.play_circle_outline_rounded,
            color: Colors.white.withValues(alpha: 0.6), size: 80),
      ),
    );
  }
}
