import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> register({
    required String email,
    required String password,
    required String username,
    required AgeGroup ageGroup,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      id: cred.user!.uid,
      email: email,
      username: username,
      ageGroup: ageGroup,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.id).set(user.toMap());
    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _db.collection('users').doc(cred.user!.uid).get();

    if (!doc.exists) {
      final user = UserModel(
        id: cred.user!.uid,
        email: email,
        username: email.split('@')[0],
        ageGroup: AgeGroup.kids,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.id).set(user.toMap());
      return user;
    }

    return UserModel.fromMap(doc.data()!);
  }

  Future<void> logout() => _auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}