import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _currentUser = _authService.currentUser;
  }

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isTutor => _currentUser?.isTutor ?? false;
  bool get isParent => _currentUser?.isParent ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String username,
    required String pin,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(username: username, pin: pin);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String pin,
    required String name,
    required String role,
    String? studentId,
    String? studentRollNo,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.register(
        username: username,
        pin: pin,
        name: name,
        role: role,
        studentId: studentId,
        studentRollNo: studentRollNo,
        phone: phone,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
