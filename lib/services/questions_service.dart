import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<QuestionModel>> getQuestions({
    required String categoryId,
    required String topicId,
    List<String> excludeIds = const [],
    int limit = 10,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);

    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    final snap = await query.get();
    final allQuestions = snap.docs
        .map((doc) => QuestionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final filtered = allQuestions
        .where((q) => !excludeIds.contains(q.id))
        .toList()
      ..shuffle();

    return filtered.take(limit).toList();
  }

  Future<void> seedQuestions(List<QuestionModel> questions) async {
    final batch = _db.batch();
    for (final q in questions) {
      final doc = q.id.isNotEmpty
          ? _db.collection('questions').doc(q.id)
          : _db.collection('questions').doc();
      batch.set(doc, q.toMap()..['id'] = doc.id);
    }
    await batch.commit();
  }

  Future<void> saveResult(QuizResultModel result) async {
    final doc = _db.collection('quiz_results').doc();
    await doc.set(result.toMap()..['id'] = doc.id);
  }

  Future<void> addStars({
    required String userId,
    required int starsToAdd,
  }) async {
    if (starsToAdd <= 0) return;
    await _db.collection('users').doc(userId).update({
      'totalStars': FieldValue.increment(starsToAdd),
    });
  }

  Future<void> saveAnsweredQuestions({
    required String userId,
    required List<String> questionIds,
  }) async {
    await _db.collection('users').doc(userId).update({
      'answeredQuestions': FieldValue.arrayUnion(questionIds),
    });
  }

  Future<int> getTotalQuestionsCount({
    required String categoryId,
    required String topicId,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);

    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Stream<List<QuestionModel>> watchAllQuestions() {
    return _db
        .collection('questions')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }
}