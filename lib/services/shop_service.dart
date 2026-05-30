import 'package:cloud_firestore/cloud_firestore.dart';

class ShopService {
  final _db = FirebaseFirestore.instance;

  Future<bool> _purchase({
    required String userId,
    required int price,
    required Map<String, dynamic> updates,
  }) async {
    final ref = _db.collection('users').doc(userId);
    try {
      return await _db.runTransaction<bool>((txn) async {
        final snap = await txn.get(ref);
        final coins = (snap.data()?['coins'] as int?) ?? 0;
        if (coins < price) return false;
        txn.update(ref, {'coins': FieldValue.increment(-price), ...updates});
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Future<bool> buyStreakFreeze(String userId) => _purchase(
        userId: userId,
        price: 10,
        updates: {'streakFreezeCount': FieldValue.increment(1)},
      );

  Future<bool> buyXpBoost(String userId) => _purchase(
        userId: userId,
        price: 25,
        updates: {'xpBoostActive': true},
      );

  Future<bool> buyGoldFrame(String userId) => _purchase(
        userId: userId,
        price: 50,
        updates: {'hasGoldFrame': true},
      );

  Future<void> deactivateXpBoost(String userId) async {
    await _db.collection('users').doc(userId).update({'xpBoostActive': false});
  }
}
