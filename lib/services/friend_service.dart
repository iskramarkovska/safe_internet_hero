import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch multiple users by their IDs
  Future<List<UserModel>> getUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = await _db
        .collection('users')
        .where('uid', whereIn: ids)
        .get();
    return result.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Search users by username.
  // All queries are fired in parallel so the whole search takes one network
  // round-trip worth of latency regardless of how many variants we try.
  // Each individual query is wrapped in its own try-catch so a missing index
  // or permission error never silently kills the entire search.
  Future<List<UserModel>> searchUsers(String query) async {
    final raw = query.trim();
    final lower = raw.toLowerCase();
    if (lower.isEmpty) return [];

    // Case variants for the original (non-normalised) username field.
    final variants = <String>{
      raw,
      lower,
      lower[0].toUpperCase() + (lower.length > 1 ? lower.substring(1) : ''),
      raw.toUpperCase(),
    };

    final seen = <String>{};
    final results = <UserModel>[];

    void addDocs(List<QueryDocumentSnapshot> docs) {
      for (final doc in docs) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        if (seen.add(user.id)) results.add(user);
      }
    }

    Future<void> safeQuery(Future<QuerySnapshot> q) async {
      try {
        addDocs((await q).docs);
      } catch (_) {}
    }

    // Append U+F8FF (a high private-use Unicode char) so Firestore treats
    // this as a prefix query: all strings starting with the prefix match.
    final lowerEnd = lower + String.fromCharCode(0xF8FF);

    // Run every query in parallel - one network round-trip total
    await Future.wait([
      // Exact matches
      safeQuery(_db.collection('users').where('usernameLower', isEqualTo: lower).get()),
      for (final v in variants)
        safeQuery(_db.collection('users').where('username', isEqualTo: v).get()),

      // Prefix matches
      safeQuery(_db
          .collection('users')
          .where('usernameLower', isGreaterThanOrEqualTo: lower)
          .where('usernameLower', isLessThanOrEqualTo: lowerEnd)
          .get()),
      for (final v in variants)
        safeQuery(_db
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: v)
            .where('username', isLessThanOrEqualTo: v + String.fromCharCode(0xF8FF))
            .get()),
    ]);

    return results;
  }

  // Check whether a username is already taken (case-insensitive)
  Future<bool> isUsernameTaken(String username) async {
    final snap = await _db
        .collection('users')
        .where('usernameLower', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromId, String toId) async {
    await _db.collection('users').doc(toId).update({
      'friendRequests': FieldValue.arrayUnion([fromId]),
    });
  }

  // Cancel a pending friend request
  Future<void> cancelFriendRequest(String fromId, String toId) async {
    await _db.collection('users').doc(toId).update({
      'friendRequests': FieldValue.arrayRemove([fromId]),
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String userId, String fromId) async {
    final batch = _db.batch();
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

  // Remove friend (mutual)
  Future<void> removeFriend(String userId, String friendId) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(userId), {
      'friends': FieldValue.arrayRemove([friendId]),
    });
    batch.update(_db.collection('users').doc(friendId), {
      'friends': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }
}
