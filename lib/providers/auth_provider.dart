import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../models/enums.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

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

      print('LOGIN RESULT: $_user');
      print('IS LOGGED IN: $isLoggedIn');

      notifyListeners();
      return true;
    } catch (e) {
      print('LOGIN ERROR: $e');
      _errorMessage = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> checkCurrentUser() async {
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
      if (msg.contains('wrong-password')) return 'Incorrect password.';
      if (msg.contains('user-not-found')) return 'No account found with that email.';
      if (msg.contains('weak-password')) return 'Password is too weak.';
      if (msg.contains('invalid-email')) return 'Invalid email address.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> refreshUser() async {
    _user = await _authService.getCurrentUser();
    notifyListeners();
  }
}