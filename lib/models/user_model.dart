import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final AgeGroup ageGroup;
  final int totalStars;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> friendRequests;
  final bool isAdmin;
  final List<String> answeredQuestions;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.ageGroup,
    this.totalStars = 0,
    required this.createdAt,
    this.friends = const [],
    this.friendRequests = const [],
    this.isAdmin = false,
    this.answeredQuestions = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['uid'],
    email: map['email'],
    username: map['username'],
    ageGroup: AgeGroupExtension.fromString(map['ageGroup']),
    totalStars: map['totalStars'] ?? 0,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
    friends: List<String>.from(map['friends'] ?? []),
    friendRequests: List<String>.from(map['friendRequests'] ?? []),
    isAdmin: map['isAdmin'] ?? false,
    answeredQuestions: List<String>.from(map['answeredQuestions'] ?? []),
  );

  Map<String, dynamic> toMap() => {
    'uid': id,
    'email': email,
    'username': username,
    'ageGroup': ageGroup.name,
    'totalStars': totalStars,
    'createdAt': createdAt,
    'friends': friends,
    'friendRequests': friendRequests,
    'isAdmin': isAdmin,
    'answeredQuestions': answeredQuestions,
  };
}