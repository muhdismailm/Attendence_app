import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static const String internalDomain = 'yourapp.internal';
  static const List<String> internalDomains = ['yourapp.internal', 'hazri.internal'];

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  final List<AppUser> _allUsers = [];

  /// Centralized username normalization: trims whitespace and converts to lowercase.
  static String normalizeUsername(String username) {
    return username.replaceAll(' ', '').trim().toLowerCase();
  }

  /// Centralized mapping of normalized username to internal Firebase email.
  static String usernameToInternalEmail(String username, [String domain = internalDomain]) {
    final normalized = normalizeUsername(username);
    return '$normalized@$domain';
  }

  /// Initializes auth state on application startup.
  /// Checks Firebase Auth session persistence and retrieves Firestore profile.
  Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        try {
          var doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
          Map<String, dynamic>? data = doc.data();

          // Fallback if doc is not keyed by Auth UID
          if (!doc.exists || data == null) {
            final emailPrefix = fbUser.email?.split('@').first ?? '';
            if (emailPrefix.isNotEmpty) {
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('username', isEqualTo: normalizeUsername(emailPrefix))
                  .limit(1)
                  .get();
              if (query.docs.isNotEmpty) {
                data = query.docs.first.data();
              }
            }
          }

          if (data != null) {
            final String status = (data['status'] ?? (data['active'] == true ? 'active' : 'disabled')).toString().toLowerCase();
            final String role = (data['role'] ?? '').toString().toLowerCase();

            if (status != 'disabled' && role == 'tutor') {
              _currentUser = AppUser(
                id: fbUser.uid,
                username: (data['username'] ?? '').toString(),
                name: (data['name'] ?? 'Tutor').toString(),
                role: role,
                active: status != 'disabled',
                phone: data['phone']?.toString(),
                place: data['place']?.toString(),
              );
            } else {
              await FirebaseAuth.instance.signOut();
              _currentUser = null;
            }
          } else {
            await FirebaseAuth.instance.signOut();
            _currentUser = null;
          }
        } catch (_) {
          _currentUser = null; // Don't sign out on network error, just null out local state
        }
      } else {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }
  }

  /// Authenticate tutor using Username + Password.
  /// Converts username to internal email for Firebase Auth, then loads Firestore profile.
  /// Seamlessly bridges Firestore-created accounts into Firebase Auth.
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
      UserCredential? userCredential;
      FirebaseAuthException? lastAuthException;

      // 1. Attempt Firebase Auth sign-in across supported internal domains
      for (final domain in internalDomains) {
        final email = usernameToInternalEmail(normalized, domain);
        try {
          userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: effectivePassword,
          );
          if (userCredential.user != null) break;
        } on FirebaseAuthException catch (e) {
          lastAuthException = e;
          // If wrong password, don't keep retrying other domains
          if (e.code == 'wrong-password') break;
        }
      }

      // 2. If not found in Auth, check if they exist in Firestore collection 'users'
      if (userCredential == null) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: normalized)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final docData = query.docs.first.data();
            final storedPassword = (docData['password'] ?? docData['pin'] ?? '').toString().trim();

            if (storedPassword == effectivePassword) {
              // Auto-create in Firebase Auth for seamless auth
              userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: usernameToInternalEmail(normalized, internalDomain),
                password: effectivePassword,
              );
            }
          }
        } catch (_) {
          // Firestore security rules may prevent unauthenticated reads
        }
      }

      if (userCredential == null) {
        final e = lastAuthException;
        if (e != null) {
          if (e.code == 'user-not-found' ||
              e.code == 'wrong-password' ||
              e.code == 'invalid-credential' ||
              e.code == 'invalid-email') {
            throw Exception('Incorrect username or password. Please check your credentials or request access.');
          } else if (e.code == 'user-disabled') {
            throw Exception('This account has been disabled by the administrator.');
          } else if (e.code == 'too-many-requests') {
            throw Exception('Too many failed attempts. Please try again later.');
          } else if (e.code == 'network-request-failed') {
            throw Exception('Unable to connect. Please check your internet connection and try again.');
          } else {
            throw Exception(e.message ?? 'Authentication failed. Please check your credentials.');
          }
        } else {
          throw Exception('Incorrect username or password. Please check your credentials or request access.');
        }
      }

      try {
        final uid = userCredential.user!.uid;
        var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        Map<String, dynamic>? data = doc.data();

        // If doc not found directly by UID, search by username
        if (!doc.exists || data == null) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: normalized)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            data = query.docs.first.data();
            // Sync to users/{uid} for permanent direct lookup
            await FirebaseFirestore.instance.collection('users').doc(uid).set(
              {...data, 'uid': uid},
              SetOptions(merge: true),
            );
          }
        }

        if (data == null) {
          await FirebaseAuth.instance.signOut();
          throw Exception('User profile not found in database.');
        }

        final String status = (data['status'] ?? (data['active'] == true ? 'active' : 'disabled')).toString().toLowerCase();
        final String role = (data['role'] ?? '').toString().toLowerCase();

        // 1. Account status check
        if (status == 'disabled') {
          await FirebaseAuth.instance.signOut();
          throw Exception('Your account has been disabled by the admin');
        }

        // 2. Role check: only tutor can log into this app
        if (role != 'tutor') {
          await FirebaseAuth.instance.signOut();
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
        return user;
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid username') ||
            errStr.contains('disabled') ||
            errStr.contains('unauthorized') ||
            errStr.contains('user profile not found') ||
            errStr.contains('incorrect username')) {
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
      throw Exception('Firebase is not initialized.');
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
    // Not needed for this refactor
    throw Exception('Not implemented in this refactor');
  }

  Future<void> logout() async {
    _currentUser = null;
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
  }

  List<AppUser> getAllUsers() => List.unmodifiable(_allUsers);
}
