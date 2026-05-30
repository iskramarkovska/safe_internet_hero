import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Records user activity and returns the new streak count.
  /// Call this after every successfully completed quiz.
  Future<int> recordActivity(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return 0;

    final data = doc.data()!;
    final currentStreak = (data['currentStreak'] as int?) ?? 0;
    final streakFreezeCount = (data['streakFreezeCount'] as int?) ?? 0;
    final lastActiveRaw = data['lastActiveDate'];

    DateTime? lastActive;
    if (lastActiveRaw is Timestamp) lastActive = lastActiveRaw.toDate();

    int newStreak;
    if (lastActive == null) {
      newStreak = 1;
    } else {
      final lastDay =
          DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        newStreak = currentStreak; // Already active today — preserve streak
      } else if (diff == 1) {
        newStreak = currentStreak + 1; // Consecutive day — extend
      } else if (streakFreezeCount > 0) {
        // Use a freeze instead of resetting
        newStreak = currentStreak;
        await _db.collection('users').doc(userId).update({
          'currentStreak': newStreak,
          'streakFreezeCount': FieldValue.increment(-1),
          'lastActiveDate': Timestamp.fromDate(now),
        });
        return newStreak;
      } else {
        newStreak = 1; // Missed days — reset
      }
    }

    await _db.collection('users').doc(userId).update({
      'currentStreak': newStreak,
      'lastActiveDate': Timestamp.fromDate(now),
    });

    return newStreak;
  }
}
