import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType { quizCompleted, topicCompleted, badgeEarned }

class ActivityModel {
  final String id;
  final String userId;
  final String username;
  final ActivityType type;
  final String title;
  final String description;
  final int starsEarned;
  final DateTime createdAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.type,
    required this.title,
    required this.description,
    required this.starsEarned,
    required this.createdAt,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) => ActivityModel(
    id: map['id'] ?? '',
    userId: map['userId'],
    username: map['username'],
    type: ActivityType.values.firstWhere(
          (e) => e.name == map['type'],
      orElse: () => ActivityType.quizCompleted,
    ),
    title: map['title'],
    description: map['description'],
    starsEarned: map['starsEarned'] ?? 0,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'username': username,
    'type': type.name,
    'title': title,
    'description': description,
    'starsEarned': starsEarned,
    'createdAt': createdAt,
  };
}