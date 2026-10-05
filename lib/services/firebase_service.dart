import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';

class StudentDeletionReport {
  final bool success;
  final int deletedAttendanceCount;
  final int unownedAttendanceCount;
  final String parentActionMessage;
  final String? warningMessage;

  const StudentDeletionReport({
    required this.success,
    required this.deletedAttendanceCount,
    required this.unownedAttendanceCount,
    required this.parentActionMessage,
    this.warningMessage,
  });

  String get summaryMessage {
    final buffer = StringBuffer('Student deleted permanently.');
    if (deletedAttendanceCount > 0) {
      buffer.write(' ($deletedAttendanceCount attendance records deleted)');
    }
    if (unownedAttendanceCount > 0) {
      buffer.write('\nNote: $unownedAttendanceCount attendance records with missing/null tutorId were skipped.');
    }
    if (parentActionMessage.isNotEmpty) {
      buffer.write('\nParent account: $parentActionMessage');
    }
    if (warningMessage != null) {
      buffer.write('\n$warningMessage');
    }
    return buffer.toString();
  }
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Collection References
  CollectionReference get usersRef => _firestore.collection('users');
  CollectionReference get studentsRef => _firestore.collection('students');
  CollectionReference get attendanceRef => _firestore.collection('attendance');

  // ==================== AUTHENTICATION ====================

  String _emailFromUsername(String username) {
    return '${username.trim().toLowerCase()}@hazri.internal';
  }

  Future<AppUser> registerWithUsernameAndPin({
    required String username,
    required String pin,
    required String name,
    required String role,
    String? studentId,
    String? studentRollNo,
    String? phone,
  }) async {
    final email = _emailFromUsername(username);
    final password = '${pin}000000'.substring(0, 8); // Ensure >= 6 characters for Firebase Auth

    // 1. Create in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    final appUser = AppUser(
      id: uid,
      username: username.toLowerCase(),
      pin: pin,
      name: name,
      role: role,
      studentId: studentId,
      studentRollNo: studentRollNo,
      phone: phone,
    );

    // 2. Store profile in Firestore
    await usersRef.doc(uid).set(appUser.toMap());

    return appUser;
  }

  Future<AppUser> loginWithUsernameAndPin({
    required String username,
    required String pin,
  }) async {
    final email = _emailFromUsername(username);
    final password = '${pin}000000'.substring(0, 8);

    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;
    final doc = await usersRef.doc(uid).get();

    if (!doc.exists) {
      throw Exception('User profile not found in database');
    }

    return AppUser.fromMap(doc.data() as Map<String, dynamic>, docId: uid);
  }

  // ==================== STUDENTS ====================

  Stream<List<Student>> streamStudents(String tutorId) {
    return studentsRef
        .where('tutorId', isEqualTo: tutorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Student.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    });
  }

  Future<void> addStudent(Student student) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Authentication required. Cannot add student without being logged in.');
    }

    try {
      final docRef = student.id.isNotEmpty ? studentsRef.doc(student.id) : studentsRef.doc();
      final data = student.toMap();
      data['tutorId'] = uid;
      await docRef.set(data);
    } catch (e) {
      throw Exception('Failed to add student to database: $e');
    }
  }

  Future<void> updateStudent(Student student) async {
    final data = student.toMap();
    // preserve the tutorId from the model itself
    await studentsRef.doc(student.id).update(data);
  }

  Future<void> deleteStudent(String studentId) async {
    final report = await deleteStudentCompletely(studentId);
    if (!report.success) {
      throw Exception('Failed to delete student.');
    }
  }

  /// Deletes a student completely from Cloud Firestore:
  /// 1. Ownership check: student.tutorId == current uid
  /// 2. Requires internet via Source.server
  /// 3. Deletes attendance where studentId == id AND tutorId == uid in WriteBatches of <= 400
  ///    (counts and reports docs with null/missing tutorId without failing)
  /// 4. Parent link: verifies role == 'parent' & createdBy == uid, then deletes or arrayRemoves studentId
  /// 5. Final WriteBatch: deletes students/{studentId} and parent doc (if applicable)
  Future<StudentDeletionReport> deleteStudentCompletely(String studentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Authentication required. Please sign in again.');
    }

    // Step 2: Require internet. Perform reads with Source.server; if offline, stop with clear message.
    DocumentSnapshot studentDoc;
    try {
      studentDoc = await studentsRef.doc(studentId).get(const GetOptions(source: Source.server));
    } catch (_) {
      throw Exception('Connect to the internet to delete a student permanently.');
    }

    // Step 1: Ownership check
    if (!studentDoc.exists || studentDoc.data() == null) {
      throw Exception('Student record not found on the server.');
    }

    final studentData = studentDoc.data() as Map<String, dynamic>;
    final studentTutorId = studentData['tutorId']?.toString();
    if (studentTutorId != uid) {
      throw Exception('Permission denied: You can only delete students belonging to your account.');
    }

    final parentId = studentData['parentId']?.toString().trim();

    // Step 3: Count attendance docs with null/missing tutorId first
    int unownedAttendanceCount = 0;
    try {
      final allAttendanceSnap = await attendanceRef
          .where('studentId', isEqualTo: studentId)
          .get(const GetOptions(source: Source.server));
      for (final doc in allAttendanceSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final docTutorId = data?['tutorId'];
        if (docTutorId == null || docTutorId.toString().trim().isEmpty) {
          unownedAttendanceCount++;
        }
      }
    } catch (_) {
      try {
        final nullTutorSnap = await attendanceRef
            .where('studentId', isEqualTo: studentId)
            .where('tutorId', isNull: true)
            .get(const GetOptions(source: Source.server));
        unownedAttendanceCount = nullTutorSnap.docs.length;
      } catch (_) {}
    }

    // Step 3 (cont): Delete attendance where studentId == studentId AND tutorId == uid
    // in WriteBatches of at most 400. Repeat until query returns nothing.
    int deletedAttendanceCount = 0;
    while (true) {
      final attendanceBatch = await attendanceRef
          .where('studentId', isEqualTo: studentId)
          .where('tutorId', isEqualTo: uid)
          .limit(400)
          .get(const GetOptions(source: Source.server));

      if (attendanceBatch.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      for (final doc in attendanceBatch.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deletedAttendanceCount += attendanceBatch.docs.length;
    }

    // Step 4: Parent link: read users/{student.parentId} if set
    String parentActionMessage = 'No parent account linked.';
    String? warningMessage;
    DocumentReference? parentDocToDelete;
    DocumentReference? parentDocToUpdate;

    if (parentId != null && parentId.isNotEmpty) {
      try {
        final parentDoc = await usersRef.doc(parentId).get(const GetOptions(source: Source.server));
        if (parentDoc.exists && parentDoc.data() != null) {
          final parentData = parentDoc.data() as Map<String, dynamic>;
          final role = parentData['role']?.toString();
          final createdBy = parentData['createdBy']?.toString();

          // Addition 4: Verify role == 'parent' and createdBy == current tutor uid
          if (role != 'parent' || createdBy != uid) {
            warningMessage = 'Parent account ($parentId) was not created by you or is not role "parent"; skipped modifying parent account.';
            parentActionMessage = 'Skipped (unowned or invalid role).';
          } else {
            final rawStudentIds = parentData['studentIds'];
            List<String> studentIds = [];
            if (rawStudentIds is List) {
              studentIds = rawStudentIds.map((e) => e.toString()).toList();
            }

            // If studentIds contains only this student, delete users doc
            if (studentIds.isEmpty || (studentIds.length == 1 && studentIds.contains(studentId))) {
              parentDocToDelete = parentDoc.reference;
              parentActionMessage = 'Parent account document deleted.';
            } else {
              // If it contains other students, remove only this id from studentIds
              parentDocToUpdate = parentDoc.reference;
              parentActionMessage = 'Removed child link from shared parent account (${studentIds.length - 1} sibling(s) remain).';
            }
          }
        } else {
          parentActionMessage = 'Parent document already removed or does not exist.';
        }
      } catch (e) {
        warningMessage = 'Could not access parent document ($parentId): $e';
        parentActionMessage = 'Failed to inspect parent document.';
      }
    }

    // Step 5: In one final WriteBatch: delete students/{studentId} (and parent doc if applicable)
    final finalBatch = _firestore.batch();
    finalBatch.delete(studentsRef.doc(studentId));

    if (parentDocToDelete != null) {
      finalBatch.delete(parentDocToDelete);
    } else if (parentDocToUpdate != null) {
      finalBatch.update(parentDocToUpdate, {
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
    }

    await finalBatch.commit();

    return StudentDeletionReport(
      success: true,
      deletedAttendanceCount: deletedAttendanceCount,
      unownedAttendanceCount: unownedAttendanceCount,
      parentActionMessage: parentActionMessage,
      warningMessage: warningMessage,
    );
  }

  // ==================== ATTENDANCE ====================

  Future<void> saveAttendanceBatch(List<AttendanceRecord> records) async {
    final batch = _firestore.batch();
    for (var record in records) {
      final docRef = attendanceRef.doc(record.id);
      batch.set(docRef, record.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<AttendanceRecord>> streamAttendanceForStudent(String studentId) {
    return attendanceRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    });
  }
}
