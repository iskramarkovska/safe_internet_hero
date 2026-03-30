import 'package:cloud_firestore/cloud_firestore.dart';

class TopicModel {
  final String id;
  final String categoryId;
  final String name;
  final String desc;
  final bool isNew;
  final bool isUpdated;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TopicModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.desc,
    required this.isNew,
    required this.isUpdated,
    required this.order,
    this.createdAt,
    this.updatedAt,
  });

  factory TopicModel.fromMap(Map<String, dynamic> map) {
    return TopicModel(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      desc: map['desc'] ?? '',
      isNew: map['isNew'] ?? false,
      isUpdated: map['isUpdated'] ?? false,
      order: map['order'] ?? 0,
      createdAt: _toDateTimeOrNull(map['createdAt']),
      updatedAt: _toDateTimeOrNull(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'desc': desc,
      'isNew': isNew,
      'isUpdated': isUpdated,
      'order': order,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}