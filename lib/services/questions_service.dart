import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';

class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Loads questions for a topic.
  /// [forReplay] — when true, `excludeIds` is ignored so users can redo a topic.
  /// [specificIds] — when provided, loads those exact question IDs (practice mode).
  Future<List<QuestionModel>> getQuestions({
    required String categoryId,
    required String topicId,
    List<String> excludeIds = const [],
    int limit = 10,
    bool forReplay = false,
  }) async {
    Query query = _db
        .collection('questions')
        .where('categoryId', isEqualTo: categoryId);

    if (topicId.isNotEmpty) {
      query = query.where('topicId', isEqualTo: topicId);
    }

    final snap = await query.get();
    final allQuestions = snap.docs
        .map((doc) => QuestionModel.fromMap(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .toList();

    final filtered = forReplay
        ? allQuestions
        : allQuestions.where((q) => !excludeIds.contains(q.id)).toList();

    return (filtered..shuffle()).take(limit).toList();
  }

  /// Loads specific questions by their document IDs (used for practice mode).
  Future<List<QuestionModel>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn supports up to 30 items; chunk just in case.
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10).clamp(0, ids.length)));
    }
    final futures = chunks.map((chunk) => _db
        .collection('questions')
        .where(FieldPath.documentId, whereIn: chunk)
        .get());
    final snaps = await Future.wait(futures);
    return snaps
        .expand((s) => s.docs)
        .map((doc) => QuestionModel.fromMap(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>}))
        .toList()
      ..shuffle();
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

  /// Awards stars and coins to a user atomically.
  Future<void> addRewards({
    required String userId,
    required int starsToAdd,
    required int coinsToAdd,
  }) async {
    final updates = <String, dynamic>{};
    if (starsToAdd > 0) updates['totalStars'] = FieldValue.increment(starsToAdd);
    if (coinsToAdd > 0) updates['coins'] = FieldValue.increment(coinsToAdd);
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
  }

  /// Updates the user's answered/incorrect question lists.
  /// Correctly answered questions are added to [answeredQuestions] and
  /// removed from [incorrectlyAnsweredIds]. Incorrectly answered questions
  /// are added to [incorrectlyAnsweredIds].
  Future<void> saveAnsweredQuestions({
    required String userId,
    required List<String> correctIds,
    required List<String> incorrectIds,
  }) async {
    final updates = <String, dynamic>{};

    if (correctIds.isNotEmpty) {
      updates['answeredQuestions'] = FieldValue.arrayUnion(correctIds);
      // Remove from weak list when answered correctly
      updates['incorrectlyAnsweredIds'] = FieldValue.arrayRemove(correctIds);
    }

    if (incorrectIds.isNotEmpty) {
      updates['incorrectlyAnsweredIds'] = FieldValue.arrayUnion(incorrectIds);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(userId).update(updates);
    }
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
    return _db.collection('questions').snapshots().map((snap) => snap.docs
        .map((doc) =>
            QuestionModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }
}
