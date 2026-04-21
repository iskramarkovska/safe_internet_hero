import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ignore_for_file: unused_element

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimmer({required Widget child}) => Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: child,
    );

class TopicSkeletonCard extends StatelessWidget {
  const TopicSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const _Bone(width: 52, height: 52, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(
                    width: MediaQuery.of(context).size.width * 0.35,
                    height: 18,
                    radius: 9,
                  ),
                  const SizedBox(height: 8),
                  const _Bone(width: 80, height: 12, radius: 6),
                  const SizedBox(height: 8),
                  const _Bone(width: double.infinity, height: 6, radius: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContentSkeletonCard extends StatelessWidget {
  const ContentSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(width: 60, height: 18, radius: 6),
                  SizedBox(height: 8),
                  _Bone(width: double.infinity, height: 16, radius: 8),
                  SizedBox(height: 6),
                  _Bone(width: double.infinity, height: 12, radius: 6),
                  SizedBox(height: 4),
                  _Bone(width: 160, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Leaderboard skeletons
// ─────────────────────────────────────────────────────

class LeaderboardPodiumSkeleton extends StatelessWidget {
  const LeaderboardPodiumSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        height: 185,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _PodiumColSkeleton(height: 90),
            _PodiumColSkeleton(height: 120),
            _PodiumColSkeleton(height: 70),
          ],
        ),
      ),
    );
  }
}

class _PodiumColSkeleton extends StatelessWidget {
  final double height;
  const _PodiumColSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const _Bone(width: 40, height: 40, radius: 20),
        const SizedBox(height: 8),
        _Bone(width: 76, height: height, radius: 6),
      ],
    );
  }
}

class LeaderboardRowSkeleton extends StatelessWidget {
  const LeaderboardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            _Bone(width: 28, height: 14, radius: 7),
            SizedBox(width: 10),
            _Bone(width: 36, height: 36, radius: 18),
            SizedBox(width: 12),
            Expanded(
                child: _Bone(width: double.infinity, height: 14, radius: 7)),
            SizedBox(width: 12),
            _Bone(width: 44, height: 14, radius: 7),
          ],
        ),
      ),
    );
  }
}
