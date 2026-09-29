import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _currentUser = _authService.currentUser;
    _status = _currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isAuthenticated => _currentUser != null;
  bool get isTutor => _currentUser?.isTutor ?? false;
  bool get isParent => _currentUser?.isParent ?? false;
  bool get isLoading => _status == AuthStatus.loading;
  String? get errorMessage => _errorMessage;

  /// Check authentication status on startup / resume
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.initialize();
      _currentUser = _authService.currentUser;
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  /// Login using Username and Password provided by administrator
  Future<bool> login({
    required String username,
    String? password,
    String? pin, // Support legacy parameter alias
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        username: username,
        password: password,
        pin: pin,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _currentUser = null;
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    String? password,
    String? pin,
    required String name,
    required String role,
    String? studentId,
    String? studentRollNo,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        password: password,
        pin: pin,
        name: name,
        role: role,
        studentId: studentId,
        studentRollNo: studentRollNo,
        phone: phone,
      );

      // For tutors, do not automatically log them in; just submit access request
      if (role == 'tutor') {
        _errorMessage = 'Registration request submitted. Please wait for admin approval.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true; 
      } else {
        // For parents/mock fallback
        _currentUser = _authService.currentUser;
        _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign out the current tutor
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Verification check for sensitive dialog actions (e.g. deleting team)
  bool verifyPin(String pin) {
    if (_currentUser == null) return false;
    if (_currentUser!.pin.isNotEmpty) {
      return _currentUser!.pin.trim() == pin.trim();
    }
    // Default fallback for mock actions
    return pin.trim() == '1234';
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
