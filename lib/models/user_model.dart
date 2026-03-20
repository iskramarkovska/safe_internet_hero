import 'package:cloud_firestore/cloud_firestore.dart';


enum AgeGroup{
  kids,
  tweens,
  teens,
}

extension AgeGroupExtension on AgeGroup {
  String get label {
    switch (this) {
      case AgeGroup.kids:   return 'Kids (6–9)';
      case AgeGroup.tweens: return 'Tweens (10–13)';
      case AgeGroup.teens:  return 'Teens (14+)';
    }
  }

  static AgeGroup fromString(String value) {
    return AgeGroup.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AgeGroup.kids,
    );
  }
}

class UserModel{
  final String id;
  final String email;
  final String username;
  final AgeGroup  ageGroup;
  final int totalStars;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.ageGroup,
    this.totalStars = 0,
    required this.createdAt,
  });



  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['uid'],
    email:      map['email'],
    username:   map['username'],
    ageGroup:   AgeGroupExtension.fromString(map['ageGroup']),
    totalStars: map['totalStars'] ?? 0,
    createdAt:  (map['createdAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'id':        id,
    'email':      email,
    'username':   username,
    'ageGroup':   ageGroup.name,
    'totalStars': totalStars,
    'createdAt':  createdAt,
  };
}