import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:attandence_app/main.dart';
import 'package:attandence_app/services/auth_service.dart';
import 'package:attandence_app/services/database_service.dart';
import 'package:attandence_app/state/auth_provider.dart';
import 'package:attandence_app/state/student_provider.dart';
import 'package:attandence_app/state/attendance_provider.dart';
import 'package:attandence_app/models/student_model.dart';
import 'package:attandence_app/models/attendance_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('Attendance App Core Unit & Logic Tests', () {
    test('Student and Attendance deterministic ID generation', () {
      final id = AttendanceRecord.generateId('stud_01', '2026-09-02');
      expect(id, equals('stud_01_2026-09-02'));
    });

    test('AuthService login and register with 4-digit PIN', () async {
      final authService = AuthService();
      await authService.initialize();

      // Test default tutor login
      final tutor = await authService.login(username: 'tutor', pin: '1234');
      expect(tutor.isTutor, isTrue);
      expect(tutor.name, contains('Robert'));

      // Test parent registration with 4-digit PIN
      final newParent = await authService.register(
        username: 'testparent',
        pin: '5678',
        name: 'Test Parent',
        role: 'parent',
        studentId: 'stud_t1_m_01',
      );
      expect(newParent.isParent, isTrue);
      expect(newParent.username, equals('testparent'));
      expect(newParent.pin, equals('5678'));
    });

    test('DatabaseService student management and group distribution', () async {
      final dbService = DatabaseService();
      await dbService.initialize();

      final allStudents = dbService.getAllStudents();
      expect(allStudents.length, greaterThanOrEqualTo(25));

      final t1Morning = dbService.getStudentsByGroup(team: 'team1', timing: 'morning');
      expect(t1Morning.length, greaterThanOrEqualTo(8));

      final t2Evening = dbService.getStudentsByGroup(team: 'team2', timing: 'evening');
      expect(t2Evening.length, greaterThanOrEqualTo(5));

      // Test adding student
      const newStudent = Student(
        id: 'new_01',
        name: 'Deepak Sharma',
        rollNumber: '99',
        team: 'team1',
        timing: 'morning',
        parentName: 'R. Sharma',
        parentPhone: '+91 9999999999',
        parentEmail: 'r@sharma.com',
        active: true,
      );
      await dbService.addStudent(newStudent);
      final found = dbService.getStudentById('new_01');
      expect(found, isNotNull);
      expect(found!.name, equals('Deepak Sharma'));
    });

    test('AttendanceProvider marking workflow and batch save', () async {
      final dbService = DatabaseService();
      await dbService.initialize();

      final attProv = AttendanceProvider(dbService);
      attProv.initMarkingSession(team: 'team1', timing: 'morning');

      final students = dbService.getStudentsByGroup(team: 'team1', timing: 'morning');
      expect(students, isNotEmpty);

      // Mark all present
      attProv.markAllPresent(students);
      expect(attProv.presentCountInSession, equals(students.length));

      // Toggle first student to absent
      attProv.toggleStudentStatus(students.first.id);
      expect(attProv.absentCountInSession, equals(1));
      expect(attProv.presentCountInSession, equals(students.length - 1));

      // Save attendance
      final saved = await attProv.saveAttendance(students: students, tutorId: 'tutor_01');
      expect(saved, isTrue);

      // Validate stats
      final stats = attProv.getStudentStats(students.first.id);
      expect(stats['totalClasses'], greaterThan(0));
    });
  });

  testWidgets('App renders LoginScreen when unauthenticated', (WidgetTester tester) async {
    final authService = AuthService();
    final dbService = DatabaseService();

    await authService.initialize();
    await dbService.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
          ChangeNotifierProvider(create: (_) => StudentProvider(dbService)),
          ChangeNotifierProvider(create: (_) => AttendanceProvider(dbService)),
        ],
        child: const AttendanceApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('4-Digit PIN / Password'), findsWidgets);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
