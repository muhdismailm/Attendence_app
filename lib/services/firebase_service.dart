import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';

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
    return '${username.trim().toLowerCase()}@attendanceapp.local';
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

  Stream<List<Student>> streamStudents() {
    return studentsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Student.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
    });
  }

  Future<void> addStudent(Student student) async {
    final docRef = student.id.isNotEmpty ? studentsRef.doc(student.id) : studentsRef.doc();
    await docRef.set(student.toMap());
  }

  Future<void> updateStudent(Student student) async {
    await studentsRef.doc(student.id).update(student.toMap());
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
