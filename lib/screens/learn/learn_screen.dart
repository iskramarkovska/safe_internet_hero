import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_page_route.dart';
import '../../core/theme.dart';
import '../../models/learning_content_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton_loader.dart';
import 'article_screen.dart';
import 'video_screen.dart';

// ─── Content-type filter options ──────────────────────────────────────────────

enum _TypeFilter { all, articles, videos }

extension _TypeFilterX on _TypeFilter {
  String get label => switch (this) {
        _TypeFilter.all => 'All',
        _TypeFilter.articles => 'Articles',
        _TypeFilter.videos => 'Videos',
      };

  IconData get icon => switch (this) {
        _TypeFilter.all => Icons.apps_rounded,
        _TypeFilter.articles => Icons.article_rounded,
        _TypeFilter.videos => Icons.play_circle_rounded,
      };

  Color get color => AppColors.blue;

  bool matches(LearningContentModel item) => switch (this) {
        _TypeFilter.all =>
          item.type == ContentType.article || item.type == ContentType.video,
        _TypeFilter.articles => item.type == ContentType.article,
        _TypeFilter.videos => item.type == ContentType.video,
      };
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final LearningService _learningService = LearningService();
  _TypeFilter _filter = _TypeFilter.all;

  void _openContent(LearningContentModel item) {
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => item.type == ContentType.video
            ? VideoScreen(content: item)
            : ArticleScreen(content: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final stars = user?.totalStars ?? 0;
    final streak = user?.currentStreak ?? 0;
    final coins = user?.coins ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppTopBar(stars: stars, streak: streak, coins: coins),
                Container(height: 1, color: AppColors.border),

                // Blue gradient title — same style as Leaderboard
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                        'Learn',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Read articles, watch videos and level up!',
                        style: GoogleFonts.nunito(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Type filter chips
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: _TypeFilter.values
                        .map((f) => _TypeChip(
                              filter: f,
                              selected: _filter == f,
                              onTap: () => setState(() => _filter = f),
                            ))
                        .toList(),
                  ),
                ),
                Container(height: 1, color: AppColors.border),
              ],
            ),
          ),

          // ── Content list ──────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<LearningContentModel>>(
              stream: _learningService.getAllContent(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: List.generate(
                        4, (_) => const ContentSkeletonCard()),
                  );
                }

                final items = snap.data!
                    .where(_filter.matches)
                    .toList();

                if (items.isEmpty) {
                  return _EmptyState(filter: _filter);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ContentCard(
                    item: items[i],
                    onTap: () => _openContent(items[i]),
                  )
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 300.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final _TypeFilter filter;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filter.color;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                color: selected ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(height: 3),
              Text(
                filter.label,
                style: GoogleFonts.nunito(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _TypeFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final color = filter.color;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(filter.icon, color: color, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'No ${filter.label.toLowerCase()} yet',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon — new content\nis on the way!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content card ─────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final LearningContentModel item;
  final VoidCallback onTap;

  const _ContentCard({required this.item, required this.onTap});

  static Color _typeColor(ContentType t) => switch (t) {
        ContentType.video => const Color(0xFFFF0000),
        ContentType.infographic => AppColors.orange,
        _ => AppColors.teal,
      };

  static IconData _typeIcon(ContentType t) => switch (t) {
        ContentType.video => Icons.play_circle_rounded,
        ContentType.infographic => Icons.image_rounded,
        _ => Icons.article_rounded,
      };

  static String _typeLabel(ContentType t) => switch (t) {
        ContentType.video => 'VIDEO',
        ContentType.infographic => 'IMAGE',
        _ => 'ARTICLE',
      };

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    final icon = _typeIcon(item.type);
    final label = _typeLabel(item.type);
    final isVideo = item.type == ContentType.video;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: Stack(
                  children: [
                    item.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            item.thumbnailUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ThumbnailPlaceholder(
                                    color: color, icon: icon),
                          )
                        : _ThumbnailPlaceholder(color: color, icon: icon),

                    // Video play button overlay
                    if (isVideo)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          child: Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF0000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ),

                    // Type badge — top left
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Read time badge — top right
                    if (!isVideo && item.readTimeMinutes > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: Colors.white, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                '${item.readTimeMinutes} min',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Info section ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // XP earned chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.green
                                    .withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.green, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                isVideo
                                    ? '+5 XP'
                                    : '+${(item.readTimeMinutes * 2).clamp(4, 20)} XP',
                                style: GoogleFonts.nunito(
                                  color: AppColors.greenDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isVideo ? 'Watch now' : 'Read now',
                          style: GoogleFonts.nunito(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.blue, size: 11),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Thumbnail placeholder ────────────────────────────────────────────────────

class _ThumbnailPlaceholder extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _ThumbnailPlaceholder(
      {required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.white, 0.3) ?? color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon,
            color: Colors.white.withValues(alpha: 0.5), size: 60),
      ),
    );
  }
}
