import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final AgeGroup ageGroup;
  final int totalStars;
  final int coins;
  final int currentStreak;
  final DateTime? lastActiveDate;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> friendRequests;
  final bool isAdmin;
  final List<String> answeredQuestions;
  final List<String> incorrectlyAnsweredIds;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.ageGroup,
    this.totalStars = 0,
    this.coins = 0,
    this.currentStreak = 0,
    this.lastActiveDate,
    required this.createdAt,
    this.friends = const [],
    this.friendRequests = const [],
    this.isAdmin = false,
    this.answeredQuestions = const [],
    this.incorrectlyAnsweredIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['uid'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      ageGroup: AgeGroupExtension.fromString(map['ageGroup'] ?? 'kids'),
      totalStars: map['totalStars'] ?? 0,
      coins: map['coins'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      lastActiveDate: _toDateTimeNullable(map['lastActiveDate']),
      createdAt: _toDateTime(map['createdAt']),
      friends: List<String>.from(map['friends'] ?? []),
      friendRequests: List<String>.from(map['friendRequests'] ?? []),
      isAdmin: map['isAdmin'] ?? false,
      answeredQuestions: List<String>.from(map['answeredQuestions'] ?? []),
      incorrectlyAnsweredIds:
          List<String>.from(map['incorrectlyAnsweredIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'username': username,
      'ageGroup': ageGroup.name,
      'totalStars': totalStars,
      'coins': coins,
      'currentStreak': currentStreak,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'friends': friends,
      'friendRequests': friendRequests,
      'isAdmin': isAdmin,
      'answeredQuestions': answeredQuestions,
      'incorrectlyAnsweredIds': incorrectlyAnsweredIds,
      'usernameLower': username.toLowerCase(),
    };
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _toDateTimeNullable(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
