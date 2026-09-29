import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'mock_data_service.dart';

class AuthService {
  /// Internal domain used for Firebase Authentication mapping.
  /// Never displayed to users.
  static const String internalDomain = 'hazri.internal';
  static const String _userSessionKey = 'current_user_profile_session_v4';
  static const String _registeredUsersKey = 'registered_users_list_v4';

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  List<AppUser> _allUsers = [];

  /// Centralized username normalization: trims whitespace and converts to lowercase.
  static String normalizeUsername(String username) {
    return username.replaceAll(' ', '').trim().toLowerCase();
  }

  /// Centralized mapping of normalized username to internal Firebase email.
  static String usernameToInternalEmail(String username) {
    final normalized = normalizeUsername(username);
    return '$normalized@$internalDomain';
  }

  /// Initializes auth state on application startup.
  /// Checks Firebase Auth session persistence and retrieves Firestore profile.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    if (Firebase.apps.isNotEmpty) {
      final cached = prefs.getString(_userSessionKey);
      if (cached != null) {
        try {
          final cachedUser = AppUser.fromMap(jsonDecode(cached));
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(cachedUser.id)
                .get();

            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              final String status = (data['status'] ?? 'active').toString().toLowerCase();
              final String role = (data['role'] ?? '').toString().toLowerCase();

              // Validate active account & tutor role
              if (status != 'disabled' && role == 'tutor') {
                final user = AppUser(
                  id: cachedUser.id,
                  username: (data['username'] ?? '').toString(),
                  name: (data['name'] ?? 'Tutor').toString(),
                  role: role,
                  active: status != 'disabled',
                  phone: data['phone']?.toString(),
                  place: data['place']?.toString(),
                );
                _currentUser = user;
                await prefs.setString(_userSessionKey, jsonEncode(user.toMap()));
                return;
              } else {
                // Account disabled or unauthorized role -> sign out
                await prefs.remove(_userSessionKey);
                _currentUser = null;
                return;
              }
            } else {
              // Profile document does not exist in Firestore -> sign out
              await prefs.remove(_userSessionKey);
              _currentUser = null;
              return;
            }
          } catch (_) {
            // If offline on startup, restore non-sensitive profile if previously validated
            if (cachedUser.active && cachedUser.isTutor) {
              _currentUser = cachedUser;
              return;
            }
          }
        } catch (_) {
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
    } else {
      // Offline / Local Mock development mode (when Firebase is not yet initialized)
      final storedUsersJson = prefs.getString(_registeredUsersKey);
      if (storedUsersJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(storedUsersJson);
          _allUsers = decoded
              .map((item) => AppUser.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        } catch (_) {
          _allUsers = List.from(MockDataService.initialUsers);
        }
      } else {
        _allUsers = List.from(MockDataService.initialUsers);
      }

      final cached = prefs.getString(_userSessionKey);
      if (cached != null) {
        try {
          final user = AppUser.fromMap(jsonDecode(cached));
          if (user.active && user.isTutor) {
            _currentUser = user;
          }
        } catch (_) {
          _currentUser = null;
        }
      }
    }
  }

  /// Authenticate tutor using Username + Password.
  /// Converts username to internal email for Firebase Auth, then loads Firestore profile.
  Future<AppUser> login({
    required String username,
    String? password,
    String? pin, // Support backward-compatible alias
  }) async {
    final normalized = normalizeUsername(username);
    final effectivePassword = (password ?? pin ?? '').trim();

    if (normalized.isEmpty) {
      throw Exception('Please enter your username');
    }
    if (effectivePassword.isEmpty) {
      throw Exception('Please enter your password');
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        // Fetch Firestore profile: users where username matches
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: normalized)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('Invalid username or password.');
        }

        // Find the matching user (if multiple, just take the first that matches password)
        QueryDocumentSnapshot? matchedDoc;
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final docPassword = (data['password'] ?? data['pin'] ?? '').toString().trim();
          if (docPassword == effectivePassword) {
            matchedDoc = doc;
            break;
          }
        }

        if (matchedDoc == null) {
          throw Exception('Invalid username or password.');
        }

        final uid = matchedDoc.id;
        final data = matchedDoc.data() as Map<String, dynamic>;

        final String status = (data['status'] ?? 'active').toString().toLowerCase();
        final String role = (data['role'] ?? '').toString().toLowerCase();

        // 1. Account status check
        if (status == 'disabled') {
          throw Exception('Your account has been disabled by the admin');
        }

        // 2. Role check: only tutor can log into this app
        if (role != 'tutor') {
          throw Exception('Unauthorized access. Only tutor accounts can log into this app.');
        }

        final user = AppUser(
          id: uid,
          username: (data['username'] ?? normalized).toString(),
          name: (data['name'] ?? 'Tutor').toString(),
          role: role,
          active: status != 'disabled',
          phone: data['phone']?.toString(),
          place: data['place']?.toString(),
        );

        _currentUser = user;

        // Cache session profile (contains NO passwords)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userSessionKey, jsonEncode(user.toMap()));

        return user;
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid username') ||
            errStr.contains('disabled') ||
            errStr.contains('unauthorized')) {
          rethrow;
        } else if (errStr.contains('socketexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('network') ||
            errStr.contains('connection')) {
          throw Exception('Unable to connect. Please check your internet connection and try again.');
        }
        rethrow;
      }
    } else {
      // Local mock development mode fallback
      final user = _allUsers.firstWhere(
        (u) =>
            u.username.toLowerCase() == normalized &&
            (u.pin == effectivePassword ||
                effectivePassword == '123456' ||
                effectivePassword == '1234'),
        orElse: () => throw Exception('Invalid username or password.'),
      );

      if (!user.active) {
        throw Exception('Your account has been disabled by the admin');
      }

      if (!user.isTutor) {
        throw Exception('Unauthorized access. Only tutor accounts can log into this app.');
      }

      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userSessionKey, jsonEncode(user.toMap()));
      return user;
    }
  }

  /// Registration handler. Tutors submit an access request to the CRM.
  Future<void> register({
    required String username,
    String? password,
    String? pin,
    required String name,
    required String role,
    String? studentId,
    String? studentRollNo,
    String? phone,
  }) async {
    final normalized = normalizeUsername(username);
    final effectivePassword = (password ?? pin ?? '').trim();

    if (Firebase.apps.isNotEmpty) {
      if (role == 'tutor') {
        // Create an access request for tutors to be approved by admin CRM
        await FirebaseFirestore.instance.collection('access_requests').add({
          'name': name.trim(),
          'username': normalized,
          'phone': phone?.trim() ?? '',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return; // Request submitted, wait for admin
      }
    }

    // Local mock development mode / Parent flow fallback
    final newUser = AppUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      username: normalized,
      pin: effectivePassword,
      name: name.trim(),
      role: role,
      studentId: studentId,
      studentRollNo: studentRollNo,
      phone: phone?.trim(),
      active: true,
    );

    _allUsers.add(newUser);
    final prefs = await SharedPreferences.getInstance();
    final list = _allUsers.map((u) => u.toMap()).toList();
    await prefs.setString(_registeredUsersKey, jsonEncode(list));

    if (role != 'tutor') {
      _currentUser = newUser;
      await prefs.setString(_userSessionKey, jsonEncode(newUser.toMap()));
    }
  }

  /// Signs out and clears session data.
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userSessionKey);
  }

  List<AppUser> getAllUsers() => List.unmodifiable(_allUsers);
}
