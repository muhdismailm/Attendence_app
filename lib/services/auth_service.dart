import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

class AuthService {
  static const String _userKey = 'current_user_data_v3';
  static const String _registeredUsersKey = 'registered_users_list_v3';

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  List<AppUser> _allUsers = [];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load registered users from storage or fallback to mock users
    final storedUsersJson = prefs.getString(_registeredUsersKey);
    if (storedUsersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(storedUsersJson);
        _allUsers = decoded.map((item) => AppUser.fromMap(Map<String, dynamic>.from(item))).toList();
      } catch (_) {
        _allUsers = List.from(MockDataService.initialUsers);
      }
    } else {
      _allUsers = List.from(MockDataService.initialUsers);
      await _saveUsersList(prefs);
    }

    // Load active session
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      try {
        _currentUser = AppUser.fromMap(jsonDecode(userData));
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<void> _saveUsersList(SharedPreferences prefs) async {
    final list = _allUsers.map((u) => u.toMap()).toList();
    await prefs.setString(_registeredUsersKey, jsonEncode(list));
  }

  Future<AppUser> login({
    required String username,
    required String pin,
  }) async {
    final trimmedUsername = username.trim().toLowerCase();
    final trimmedPin = pin.trim();

    if (trimmedUsername.isEmpty) {
      throw Exception('Please enter your username');
    }
    if (trimmedPin.length != 4) {
      throw Exception('PIN must be exactly 4 digits');
    }

    final user = _allUsers.firstWhere(
      (u) => u.username.toLowerCase() == trimmedUsername && u.pin == trimmedPin,
      orElse: () => throw Exception('Invalid username or 4-digit PIN'),
    );

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));

    return user;
  }

  Future<AppUser> register({
    required String username,
    required String pin,
    required String name,
    required String role,
    String? studentId,
    String? studentRollNo,
    String? phone,
  }) async {
    final trimmedUsername = username.trim().toLowerCase();
    final trimmedPin = pin.trim();

    if (trimmedUsername.length < 3) {
      throw Exception('Username must be at least 3 characters');
    }
    if (trimmedPin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(trimmedPin)) {
      throw Exception('PIN must be a 4-digit number');
    }
    if (name.trim().isEmpty) {
      throw Exception('Please enter your full name');
    }

    final exists = _allUsers.any((u) => u.username.toLowerCase() == trimmedUsername);
    if (exists) {
      throw Exception('Username "$trimmedUsername" is already taken');
    }

    final newUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      username: trimmedUsername,
      pin: trimmedPin,
      name: name.trim(),
      role: role,
      studentId: studentId,
      studentRollNo: studentRollNo,
      phone: phone?.trim(),
    );

    _allUsers.add(newUser);
    final prefs = await SharedPreferences.getInstance();
    await _saveUsersList(prefs);

    _currentUser = newUser;
    await prefs.setString(_userKey, jsonEncode(newUser.toMap()));

    return newUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  List<AppUser> getAllUsers() => List.unmodifiable(_allUsers);
}
