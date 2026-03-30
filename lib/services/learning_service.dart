import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/learning_content_model.dart';

class LearningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LearningContentModel>> getAllContent() {
    return FirebaseFirestore.instance
        .collection('learning_content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => LearningContentModel.fromMap(doc.data()))
          .toList(),
    );
  }

  // Get all content for a category
  Stream<List<LearningContentModel>> getContentByCategory(String categoryId) {
    return _db
        .collection('learning_content')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => LearningContentModel.fromMap(doc.data()))
        .toList());
  }

  // Get content for a specific topic
  Stream<List<LearningContentModel>> getContentByTopic(String topicId) {
    return _db
        .collection('learning_content')
        .where('topicId', isEqualTo: topicId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => LearningContentModel.fromMap(doc.data()))
        .toList());
  }

  // Save content (used by admin)
  Future<void> saveContent(LearningContentModel content) async {
    final doc = _db.collection('learning_content').doc();
    await doc.set(content.toMap()..['id'] = doc.id);
  }

  // Delete content
  Future<void> deleteContent(String id) async {
    await _db.collection('learning_content').doc(id).delete();
  }
}