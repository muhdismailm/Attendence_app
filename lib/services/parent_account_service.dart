import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ParentCredentials {
  final String loginId;
  final String pin;

  const ParentCredentials({
    required this.loginId,
    required this.pin,
  });
}

class ParentAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _primaryAuth = FirebaseAuth.instance;

  static const String _allowedChars = 'abcdefghjkmnpqrstuvwxyz23456789';

  /// Generates a login ID: "p-" + 6 random chars from "abcdefghjkmnpqrstuvwxyz23456789"
  static String generateRandomLoginId() {
    final rnd = Random.secure();
    final buffer = StringBuffer('p-');
    for (int i = 0; i < 6; i++) {
      buffer.write(_allowedChars[rnd.nextInt(_allowedChars.length)]);
    }
    return buffer.toString();
  }

  /// Generates a random 6-digit PIN using Random.secure()
  static String generateRandomPin() {
    final rnd = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < 6; i++) {
      buffer.write(rnd.nextInt(10));
    }
    return buffer.toString();
  }

  /// Helper to safely initialize and acquire a secondary Firebase Auth session
  /// without affecting the tutor's active primary Auth session.
  Future<FirebaseApp> _getSecondaryApp() async {
    const appName = 'parentCreator';
    try {
      final existing = Firebase.app(appName);
      await existing.delete();
    } catch (_) {
      // App does not exist yet
    }
    return await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );
  }

  /// Creates a parent account for a student.
  /// Refuses if student.parentId is already set.
  Future<ParentCredentials> createParentAccount(Student student) async {
    if (student.parentId != null && student.parentId!.trim().isNotEmpty) {
      throw Exception('Student already has a linked parent account.');
    }
    return _createOrReissueParentAccount(student: student, oldParentUid: null);
  }

  /// Issues a new parent login for a student:
  /// Creates a new Auth account + user doc, deactivates the old user doc,
  /// and repoints student.parentId to the new parentUid.
  Future<ParentCredentials> issueNewParentLogin(Student student) async {
    return _createOrReissueParentAccount(
      student: student,
      oldParentUid: student.parentId,
    );
  }

  /// Internal handler for creating or reissuing parent credentials.
  Future<ParentCredentials> _createOrReissueParentAccount({
    required Student student,
    String? oldParentUid,
  }) async {
    final tutorUid = _primaryAuth.currentUser?.uid;
    if (tutorUid == null) {
      throw Exception('Tutor session expired. Please sign in again.');
    }

    final secondaryApp = await _getSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    UserCredential? credential;
    String? generatedLoginId;
    String? generatedPin;

    try {
      // Step 2: Generate loginId + PIN and create Auth user with retries (max 5)
      for (int attempt = 0; attempt < 5; attempt++) {
        final candidateId = generateRandomLoginId();
        final candidatePin = generateRandomPin();
        final email = AuthService.usernameToInternalEmail(candidateId);

        try {
          credential = await secondaryAuth.createUserWithEmailAndPassword(
            email: email,
            password: candidatePin,
          );
          generatedLoginId = candidateId;
          generatedPin = candidatePin;
          break;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            continue;
          }
          rethrow;
        }
      }

      if (credential == null || generatedLoginId == null || generatedPin == null) {
        throw Exception('Failed to generate a unique parent login ID. Please try again.');
      }

      final parentUid = credential.user!.uid;

      // Step 4: Using primary Firestore session, in ONE WriteBatch
      final batch = _firestore.batch();
      final parentDocRef = _firestore.collection('users').doc(parentUid);
      final studentDocRef = _firestore.collection('students').doc(student.id);

      final parentName = student.parentName.trim().isNotEmpty
          ? student.parentName.trim()
          : 'Parent of ${student.name.trim()}';

      batch.set(parentDocRef, {
        'role': 'parent',
        'name': parentName,
        'username': generatedLoginId,
        'phone': student.parentPhone.trim(),
        'studentIds': [student.id],
        'active': true,
        'mustChangePassword': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': tutorUid,
      });

      batch.update(studentDocRef, {
        'parentId': parentUid,
      });

      // If reissuing, delete the old parent document so duplicate docs are not left behind.
      // Note: The old Firebase Auth user cannot be removed by the client (no Admin SDK)
      // and is harmless because it has no users document and is no longer linked to any student.
      if (oldParentUid != null && oldParentUid.trim().isNotEmpty) {
        final oldParentDocRef = _firestore.collection('users').doc(oldParentUid);
        batch.delete(oldParentDocRef);
      }

      try {
        await batch.commit();
      } catch (e) {
        // Step 5: If batch fails, delete the Auth user to prevent orphans
        try {
          await secondaryAuth.currentUser?.delete();
        } catch (_) {}
        rethrow;
      }

      // Step 6: Return credentials
      return ParentCredentials(
        loginId: generatedLoginId,
        pin: generatedPin,
      );
    } finally {
      // Always cleanup secondary app session
      try {
        await secondaryAuth.signOut();
      } catch (_) {}
      try {
        await secondaryApp.delete();
      } catch (_) {}
    }
  }

  /// Updates parent active flag in Firestore
  Future<void> setParentActive(String parentUid, bool active) async {
    await _firestore.collection('users').doc(parentUid).update({
      'active': active,
    });
  }

  /// Loads parent user document by parentUid
  Future<AppUser?> getParentAccount(String parentUid) async {
    final doc = await _firestore.collection('users').doc(parentUid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromMap(doc.data()!, docId: doc.id);
  }

  /// Streams parent user document by parentUid
  Stream<AppUser?> streamParentAccount(String parentUid) {
    return _firestore.collection('users').doc(parentUid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, docId: doc.id);
    });
  }
}
