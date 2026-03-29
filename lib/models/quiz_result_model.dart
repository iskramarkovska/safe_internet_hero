import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class QuizResultModel {
  final String id;
  final String userId;
  final String username;
  final String categoryId;
  final String categoryName;
  final String topicId;
  final String topicName;
  final int score;
  final int totalQuestions;
  final int starsEarned;
  final int pointsEarned;
  final DifficultyLevel difficulty;
  final DateTime completedAt;
  final List<String> correctlyAnsweredIds;

  QuizResultModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.categoryId,
    required this.categoryName,
    required this.topicId,
    required this.topicName,
    required this.score,
    required this.totalQuestions,
    required this.starsEarned,
    required this.pointsEarned,
    this.difficulty = DifficultyLevel.beginner,
    required this.completedAt,
    this.correctlyAnsweredIds = const [],
  });

  int get percentage {
    if (totalQuestions == 0) return 0;
    return ((score / totalQuestions) * 100).round();
  }

  factory QuizResultModel.fromMap(Map<String, dynamic> map) {
    return QuizResultModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      starsEarned: map['starsEarned'] ?? 0,
      pointsEarned: map['pointsEarned'] ?? 0,
      difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.name == map['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      completedAt: _toDateTime(map['completedAt']),
      correctlyAnsweredIds: List<String>.from(map['correctlyAnsweredIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'topicId': topicId,
      'topicName': topicName,
      'score': score,
      'totalQuestions': totalQuestions,
      'starsEarned': starsEarned,
      'pointsEarned': pointsEarned,
      'difficulty': difficulty.name,
      'completedAt': Timestamp.fromDate(completedAt),
      'correctlyAnsweredIds': correctlyAnsweredIds,
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}