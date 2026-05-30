import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../models/enums.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = true; // true until Firebase restores session
  bool _isGuest = false;
  String? _errorMessage;
  StreamSubscription? _authSub;

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebaseUser) async {
    if (firebaseUser == null) {
      // Explicit sign-out or no session — only clear if not guest
      if (!_isGuest) _user = null;
      _isLoading = false;
      notifyListeners();
    } else {
      // Firebase restored (or just set) a session — load profile
      try {
        _user = await _authService.getCurrentUser();
      } catch (_) {
        _user = null;
      }
      _isGuest = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null || _isGuest;
  String? get errorMessage => _errorMessage;

  void continueAsGuest() {
    _isGuest = true;
    _user = null;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required AgeGroup ageGroup,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        username: username,
        ageGroup: ageGroup,
      );
      _isGuest = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authService.login(
        email: email,
        password: password,
      );
      _isGuest = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void exitGuestMode() {
    _isGuest = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_isGuest) return;
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _handleError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('email-already-in-use')) return 'Email already registered.';
      if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        return 'Incorrect email or password.';
      }
      if (msg.contains('user-not-found')) return 'No account found with that email.';
      if (msg.contains('weak-password')) return 'Password is too weak.';
      if (msg.contains('invalid-email')) return 'Invalid email address.';
      if (msg.contains('too-many-requests')) return 'Too many attempts. Try again later.';
      if (msg.contains('network-request-failed')) return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}