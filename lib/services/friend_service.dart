import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Search users by username
  Future<List<UserModel>> searchUsers(String username) async {
    final result = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: username)
        .where('username', isLessThanOrEqualTo: '$username\uf8ff')
        .get();
    return result.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromId, String toId) async {
    await _db.collection('users').doc(toId).update({
      'friendRequests': FieldValue.arrayUnion([fromId]),
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String userId, String fromId) async {
    final batch = _db.batch();
    // Add each other as friends
    batch.update(_db.collection('users').doc(userId), {
      'friends': FieldValue.arrayUnion([fromId]),
      'friendRequests': FieldValue.arrayRemove([fromId]),
    });
    batch.update(_db.collection('users').doc(fromId), {
      'friends': FieldValue.arrayUnion([userId]),
    });
    await batch.commit();
  }

  // Decline friend request
  Future<void> declineFriendRequest(String userId, String fromId) async {
    await _db.collection('users').doc(userId).update({
      'friendRequests': FieldValue.arrayRemove([fromId]),
    });
  }

  // Get friends activity feed
  Stream<List<ActivityModel>> getFriendsActivity(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('activities')
        .where('userId', whereIn: friendIds)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ActivityModel.fromMap(doc.data()))
        .toList());
  }

  // Log activity
  Future<void> logActivity(ActivityModel activity) async {
    final doc = _db.collection('activities').doc();
    await doc.set(activity.toMap()..['id'] = doc.id);
  }
}