import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/topic_model.dart';

class TopicsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CategoryModel>> getCategories() async {
    final snap = await _db.collection('categories').orderBy('order').get();
    return snap.docs
        .map((doc) => CategoryModel.fromMap({
      'id': doc.id,
      ...doc.data(),
    }))
        .toList();
  }

  Stream<List<CategoryModel>> watchCategories() {
    return _db.collection('categories').orderBy('order').snapshots().map(
          (snap) => snap.docs
          .map((doc) => CategoryModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList(),
    );
  }

  Future<List<TopicModel>> getTopicsByCategory(String categoryId) async {
    final snap = await _db
        .collection('topics')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .get();

    return snap.docs
        .map((doc) => TopicModel.fromMap({
      'id': doc.id,
      ...doc.data(),
    }))
        .toList();
  }

  Stream<List<TopicModel>> watchTopicsByCategory(String categoryId) {
    return _db
        .collection('topics')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) => TopicModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList(),
    );
  }

  Future<List<TopicModel>> getAllTopics() async {
    final snap = await _db.collection('topics').orderBy('order').get();
    return snap.docs
        .map((doc) => TopicModel.fromMap({
      'id': doc.id,
      ...doc.data(),
    }))
        .toList();
  }

  Stream<List<TopicModel>> watchAllTopics() {
    return _db.collection('topics').orderBy('order').snapshots().map(
          (snap) => snap.docs
          .map((doc) => TopicModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList(),
    );
  }

  Future<void> saveCategory(CategoryModel category) async {
    final docRef = _db.collection('categories').doc(category.id);
    await docRef.set(category.toMap());
  }

  Future<void> saveTopic(TopicModel topic) async {
    final docRef = _db.collection('topics').doc(topic.id);
    await docRef.set(topic.toMap());
  }

  Future<void> seedCategories(List<CategoryModel> categories) async {
    final batch = _db.batch();

    for (final category in categories) {
      final docRef = _db.collection('categories').doc(category.id);
      batch.set(docRef, category.toMap());
    }

    await batch.commit();
  }

  Future<void> seedTopics(List<TopicModel> topics) async {
    final batch = _db.batch();

    for (final topic in topics) {
      final docRef = _db.collection('topics').doc(topic.id);
      batch.set(docRef, topic.toMap());
    }

    await batch.commit();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.collection('categories').doc(categoryId).delete();
  }

  Future<void> deleteTopic(String topicId) async {
    await _db.collection('topics').doc(topicId).delete();
  }
}