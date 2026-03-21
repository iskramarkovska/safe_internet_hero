import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { article, video, infographic }

class LearningContentModel {
  final String id;
  final String categoryId;
  final String topicId;
  final String title;
  final String description;
  final ContentType type;
  final String content;
  final String thumbnailUrl;
  final int readTimeMinutes;
  final DateTime createdAt;

  LearningContentModel({
    required this.id,
    required this.categoryId,
    required this.topicId,
    required this.title,
    required this.description,
    required this.type,
    required this.content,
    this.thumbnailUrl = '',
    this.readTimeMinutes = 0,
    required this.createdAt,
  });

  factory LearningContentModel.fromMap(Map<String, dynamic> map) =>
      LearningContentModel(
        id: map['id'] ?? '',
        categoryId: map['categoryId'],
        topicId: map['topicId'] ?? '',
        title: map['title'],
        description: map['description'] ?? '',
        type: ContentType.values.firstWhere(
              (e) => e.name == map['type'],
          orElse: () => ContentType.article,
        ),
        content: map['content'] ?? '',
        thumbnailUrl: map['thumbnailUrl'] ?? '',
        readTimeMinutes: map['readTimeMinutes'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'topicId': topicId,
    'title': title,
    'description': description,
    'type': type.name,
    'content': content,
    'thumbnailUrl': thumbnailUrl,
    'readTimeMinutes': readTimeMinutes,
    'createdAt': createdAt,
  };
}