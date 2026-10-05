import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attandence_app/services/database_service.dart';
import 'package:attandence_app/services/firebase_service.dart';
import 'package:attandence_app/state/attendance_provider.dart';
import 'package:attandence_app/models/student_model.dart';
import 'package:attandence_app/models/attendance_local.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Student Deletion and Reissue Unit Tests', () {
    test('Local cascade wipe removes student and pending/synced attendance from Hive', () async {
      final dbService = DatabaseService();
      // Initialize with test box
      await dbService.attendanceRepo.initialize('test_attendance_${DateTime.now().millisecondsSinceEpoch}');

      // Add a test student
      const student = Student(
        id: 'test_stud_wipe',
        name: 'Wipe Test Student',
        rollNumber: '999',
        team: 'team1',
        timing: 'morning',
        parentName: 'Parent Wipe',
        parentPhone: '9999999999',
      );
      await dbService.addStudent(student);
      expect(dbService.getStudentById('test_stud_wipe'), isNotNull);

      // Save a pending attendance record for this student
      final record = AttendanceLocal(
        id: 'test_stud_wipe_2026-09-30_morning',
        studentId: 'test_stud_wipe',
        date: '2026-09-30',
        status: 'present',
        syncStatus: 'pending',
        createdAt: DateTime.now(),
        team: 'team1',
        timing: 'morning',
      );
      await dbService.attendanceRepo.saveRecord(record);
      expect(dbService.attendanceRepo.getAttendanceRecordMap().containsKey(record.id), isTrue);

      // Perform local complete wipe
      await dbService.deleteStudentCompletelyLocal('test_stud_wipe');

      // Verify student is removed from local DB
      expect(dbService.getStudentById('test_stud_wipe'), isNull);

      // Verify attendance record (including pending) is completely wiped from Hive
      expect(dbService.attendanceRepo.getAttendanceRecordMap().containsKey(record.id), isFalse);
    });

    test('Sync Now and auto-refresh are paused while student deletion is in progress', () async {
      final dbService = DatabaseService();
      await dbService.attendanceRepo.initialize('test_sync_${DateTime.now().millisecondsSinceEpoch}');

      final attProv = AttendanceProvider(dbService);

      expect(attProv.isStudentDeletionInProgress, isFalse);

      attProv.setStudentDeletionInProgress(true);
      expect(attProv.isStudentDeletionInProgress, isTrue);

      // syncPendingAttendance must return false immediately while deletion is in progress
      final syncResult = await attProv.syncPendingAttendance(isManual: true);
      expect(syncResult, isFalse);

      // Reset
      attProv.setStudentDeletionInProgress(false);
      expect(attProv.isStudentDeletionInProgress, isFalse);
    });

    test('clearStudentAttendanceFromMemory removes student from marking session', () async {
      final dbService = DatabaseService();
      await dbService.attendanceRepo.initialize('test_mem_${DateTime.now().millisecondsSinceEpoch}');

      final attProv = AttendanceProvider(dbService);
      attProv.initMarkingSession(team: 'team1', timing: 'morning');

      // Add a status into marking session
      const student = Student(
        id: 'stud_mem_test',
        name: 'Mem Test',
        rollNumber: '888',
        team: 'team1',
        timing: 'morning',
        parentName: 'Parent',
        parentPhone: '8888888888',
      );
      attProv.markAllPresent([student]);
      expect(attProv.currentMarkingState.containsKey('stud_mem_test'), isTrue);

      // Clear from memory
      attProv.clearStudentAttendanceFromMemory('stud_mem_test');
      expect(attProv.currentMarkingState.containsKey('stud_mem_test'), isFalse);
    });

    test('Sibling array logic: retains sibling ID when one student is unlinked', () {
      final studentIds = ['child_1', 'child_2'];
      const studentToDelete = 'child_1';

      if (studentIds.length <= 1) {
        fail('Should have siblings');
      } else {
        studentIds.remove(studentToDelete);
        expect(studentIds, equals(['child_2']));
        expect(studentIds.length, equals(1));
      }
    });

    test('StudentDeletionReport formats summary accurately', () {
      const report = StudentDeletionReport(
        success: true,
        deletedAttendanceCount: 15,
        unownedAttendanceCount: 2,
        parentActionMessage: 'Parent account document deleted.',
        warningMessage: null,
      );

      expect(report.summaryMessage, contains('15 attendance records deleted'));
      expect(report.summaryMessage, contains('2 attendance records with missing/null tutorId were skipped'));
      expect(report.summaryMessage, contains('Parent account: Parent account document deleted.'));
    });
  });
}
