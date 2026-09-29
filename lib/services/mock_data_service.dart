import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/team_model.dart';
import 'package:intl/intl.dart';

class MockDataService {
  static final List<Team> initialTeams = [
    Team(
      id: 'team1',
      name: 'Team 1',
      description: 'Morning & Evening Batch 1',
      createdAt: DateTime(2026, 1, 1),
    ),
    Team(
      id: 'team2',
      name: 'Team 2',
      description: 'Morning & Evening Batch 2',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  static final List<AppUser> initialUsers = [
    const AppUser(
      id: 'tutor_001',
      username: 'tutor001',
      pin: '123456',
      name: 'Tutor One',
      role: 'tutor',
      phone: '+91 98765 43210',
      place: 'Calicut, Kerala',
      active: true,
    ),
    const AppUser(
      id: 'tutor_01',
      username: 'tutor',
      pin: '1234',
      name: 'Ismail',
      role: 'tutor',
      phone: '+91 98765 43210',
      place: 'Calicut, Kerala',
      active: true,
    ),
    const AppUser(
      id: 'parent_01',
      username: 'parent_ismail',
      pin: '1234',
      name: 'Mohammed',
      role: 'parent',
      studentId: 'stud_t1_01',
      studentRollNo: '01',
      phone: '+91 98111 00001',
    ),
    const AppUser(
      id: 'parent_02',
      username: 'parent_irshad',
      pin: '1234',
      name: 'Abdul Rahman',
      role: 'parent',
      studentId: 'stud_t1_02',
      studentRollNo: '02',
      phone: '+91 98111 00002',
    ),
    const AppUser(
      id: 'parent_03',
      username: 'parent_ihsan',
      pin: '1234',
      name: 'Ibrahim',
      role: 'parent',
      studentId: 'stud_t2_01',
      studentRollNo: '01',
      phone: '+91 98222 00001',
    ),
    const AppUser(
      id: 'parent_04',
      username: 'parent_irfana',
      pin: '1234',
      name: 'Fatima',
      role: 'parent',
      studentId: 'stud_t2_02',
      studentRollNo: '02',
      phone: '+91 98222 00002',
    ),
  ];

  static final List<Student> initialStudents = [
    // --- TEAM 1 ---
    const Student(
      id: 'stud_t1_01',
      name: 'Ismail',
      rollNumber: '01',
      team: 'team1',
      timing: 'both',
      parentId: 'parent_01',
      parentName: 'Mohammed',
      parentPhone: '+91 98111 00001',
      place: 'Calicut',
      active: true,
    ),
    const Student(
      id: 'stud_t1_02',
      name: 'Irshad',
      rollNumber: '02',
      team: 'team1',
      timing: 'both',
      parentId: 'parent_02',
      parentName: 'Abdul Rahman',
      parentPhone: '+91 98111 00002',
      place: 'Kochi',
      active: true,
    ),

    // --- TEAM 2 ---
    const Student(
      id: 'stud_t2_01',
      name: 'Ihsan',
      rollNumber: '01',
      team: 'team2',
      timing: 'both',
      parentId: 'parent_03',
      parentName: 'Ibrahim',
      parentPhone: '+91 98222 00001',
      place: 'Malappuram',
      active: true,
    ),
    const Student(
      id: 'stud_t2_02',
      name: 'Irfana',
      rollNumber: '02',
      team: 'team2',
      timing: 'both',
      parentId: 'parent_04',
      parentName: 'Fatima',
      parentPhone: '+91 98222 00002',
      place: 'Kannur',
      active: true,
    ),
  ];

  static List<AttendanceRecord> generateSampleAttendance() {
    final List<AttendanceRecord> records = [];
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    // Generate past 7 days of records for realism across both morning & evening
    for (int dayOffset = 7; dayOffset >= 0; dayOffset--) {
      final date = now.subtract(Duration(days: dayOffset));
      if (date.weekday == DateTime.sunday) continue;

      final dateStr = formatter.format(date);

      for (var student in initialStudents) {
        for (var session in ['morning', 'evening']) {
          final hash = (student.id.hashCode + date.day * 13 + session.hashCode).abs();
          final isAbsent = (hash % 8) == 0;

          records.add(
            AttendanceRecord(
              id: AttendanceRecord.generateId(student.id, dateStr, session),
              studentId: student.id,
              date: dateStr,
              status: isAbsent ? 'absent' : 'present',
              markedBy: 'tutor_01',
              team: student.team,
              timing: session,
              timestamp: date,
            ),
          );
        }
      }
    }

    return records;
  }
}
