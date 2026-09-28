import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/attendance_local.dart';
import '../models/team_model.dart';
import 'attendance_local_repository.dart';
import 'mock_data_service.dart';

class DatabaseService {
  static const String _teamsKey = 'app_teams_data_v3';
  static const String _studentsKey = 'app_students_data_v3';

  final AttendanceLocalRepository _attendanceRepo = AttendanceLocalRepository();

  List<Team> _teams = [];
  List<Student> _students = [];

  AttendanceLocalRepository get attendanceRepo => _attendanceRepo;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Initialize local Hive attendance database
    await _attendanceRepo.initialize();
    await _attendanceRepo.seedInitialDataIfEmpty(MockDataService.generateSampleAttendance());

    // 2. Load teams
    final storedTeams = prefs.getString(_teamsKey);
    if (storedTeams != null) {
      try {
        final List<dynamic> decoded = jsonDecode(storedTeams);
        _teams = decoded.map((e) => Team.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {
        _teams = List.from(MockDataService.initialTeams);
      }
    } else {
      _teams = List.from(MockDataService.initialTeams);
      await _saveTeams(prefs);
    }

    // 3. Load students
    final storedStudents = prefs.getString(_studentsKey);
    if (storedStudents != null) {
      try {
        final List<dynamic> decoded = jsonDecode(storedStudents);
        _students = decoded.map((e) => Student.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {
        _students = List.from(MockDataService.initialStudents);
      }
    } else {
      _students = List.from(MockDataService.initialStudents);
      await _saveStudents(prefs);
    }
  }

  Future<void> _saveTeams(SharedPreferences prefs) async {
    final data = _teams.map((t) => t.toMap()).toList();
    await prefs.setString(_teamsKey, jsonEncode(data));
  }

  Future<void> _saveStudents(SharedPreferences prefs) async {
    final data = _students.map((s) => s.toMap()).toList();
    await prefs.setString(_studentsKey, jsonEncode(data));
  }

  // ==================== TEAMS ====================

  List<Team> getAllTeams() => List.unmodifiable(_teams);

  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((t) => t.id.toLowerCase() == id.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  String getTeamName(String id) {
    final t = getTeamById(id);
    if (t != null) return t.name;
    if (id.toLowerCase() == 'team1') return 'Team 1';
    if (id.toLowerCase() == 'team2') return 'Team 2';
    return id.toUpperCase();
  }

  Future<Team> addTeam(Team team) async {
    final newTeam = team.copyWith(
      id: team.id.isEmpty ? 'team_${DateTime.now().millisecondsSinceEpoch}' : team.id,
      createdAt: DateTime.now(),
    );
    _teams.add(newTeam);
    final prefs = await SharedPreferences.getInstance();
    await _saveTeams(prefs);
    return newTeam;
  }

  Future<void> updateTeam(Team team) async {
    final index = _teams.indexWhere((t) => t.id.toLowerCase() == team.id.toLowerCase());
    if (index != -1) {
      _teams[index] = team;
      final prefs = await SharedPreferences.getInstance();
      await _saveTeams(prefs);
    }
  }

  /// Deletes a team and cascades deletion:
  /// - Removes all students in this team
  /// - Removes all attendance records for those students or for this team
  Future<void> deleteTeam(String teamId) async {
    final teamKey = teamId.toLowerCase();

    // 1. Remove the team
    _teams.removeWhere((t) => t.id.toLowerCase() == teamKey);

    // 2. Identify students belonging to this team
    final studentsToDelete = _students
        .where((s) => s.team.toLowerCase() == teamKey)
        .map((s) => s.id)
        .toSet();

    // 3. Remove students from this team
    _students.removeWhere((s) => s.team.toLowerCase() == teamKey);

    // 4. Cascade delete all attendance records in local Hive repository
    await _attendanceRepo.deleteRecordsForStudentOrTeam(
      studentIds: studentsToDelete,
      team: teamKey,
    );

    // 5. Persist updated teams and students
    final prefs = await SharedPreferences.getInstance();
    await _saveTeams(prefs);
    await _saveStudents(prefs);
  }

  // ==================== STUDENTS ====================

  List<Student> getAllStudents({bool includeInactive = false}) {
    if (includeInactive) return List.unmodifiable(_students);
    return _students.where((s) => s.active).toList();
  }

  List<Student> getStudentsByGroup({
    required String team,
    required String timing,
    bool includeInactive = false,
  }) {
    return _students.where((s) {
      final matchesGroup = s.team.toLowerCase() == team.toLowerCase();
      if (!matchesGroup) return false;
      return includeInactive || s.active;
    }).toList()
      ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
  }

  List<Student> getStudentsByTeam({
    required String team,
    bool includeInactive = false,
  }) {
    return _students.where((s) {
      final matchesTeam = s.team.toLowerCase() == team.toLowerCase();
      if (!matchesTeam) return false;
      return includeInactive || s.active;
    }).toList()
      ..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
  }

  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Student> addStudent(Student student) async {
    final newStudent = student.copyWith(
      id: student.id.isEmpty ? 'stud_${DateTime.now().millisecondsSinceEpoch}' : student.id,
    );
    _students.add(newStudent);
    final prefs = await SharedPreferences.getInstance();
    await _saveStudents(prefs);
    return newStudent;
  }

  Future<void> updateStudent(Student student) async {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      final prefs = await SharedPreferences.getInstance();
      await _saveStudents(prefs);
    }
  }

  Future<void> toggleStudentActive(String id) async {
    final index = _students.indexWhere((s) => s.id == id);
    if (index != -1) {
      final s = _students[index];
      _students[index] = s.copyWith(active: !s.active);
      final prefs = await SharedPreferences.getInstance();
      await _saveStudents(prefs);
    }
  }

  // ==================== ATTENDANCE (HIVE BACKED) ====================

  Map<String, AttendanceRecord> get allAttendanceMap => _attendanceRepo.getAttendanceRecordMap();

  Map<String, AttendanceRecord> getAttendanceForDateAndGroup({
    required String date,
    required String team,
    required String timing,
  }) {
    final groupStudents = getStudentsByGroup(team: team, timing: timing);
    final studentIds = groupStudents.map((s) => s.id).toSet();
    final attMap = _attendanceRepo.getAttendanceRecordMap();

    final Map<String, AttendanceRecord> result = {};
    for (var studentId in studentIds) {
      final docIdWithTiming = AttendanceRecord.generateId(studentId, date, timing);
      final docIdLegacy = AttendanceRecord.generateId(studentId, date);
      if (attMap.containsKey(docIdWithTiming)) {
        result[studentId] = attMap[docIdWithTiming]!;
      } else if (attMap.containsKey(docIdLegacy) && attMap[docIdLegacy]?.timing == timing) {
        result[studentId] = attMap[docIdLegacy]!;
      }
    }
    return result;
  }

  Future<void> saveAttendanceBatch(List<AttendanceRecord> records, {String syncStatus = 'pending'}) async {
    final locals = records.map((r) => AttendanceLocal.fromAttendanceRecord(r, syncStatus: syncStatus)).toList();
    await _attendanceRepo.saveRecordsBatch(locals);
  }

  List<AttendanceRecord> getStudentAttendanceHistory({
    required String studentId,
    int? year,
    int? month,
    String? timing,
  }) {
    final records = _attendanceRepo.getAttendanceRecordMap().values.where((r) {
      if (r.studentId != studentId) return false;
      if (timing != null && timing.isNotEmpty && r.timing != null && r.timing!.isNotEmpty) {
        if (r.timing!.toLowerCase() != timing.toLowerCase()) return false;
      }
      if (year != null && month != null) {
        final parts = r.date.split('-');
        if (parts.length == 3) {
          final rYear = int.tryParse(parts[0]);
          final rMonth = int.tryParse(parts[1]);
          return rYear == year && rMonth == month;
        }
      }
      return true;
    }).toList();

    records.sort((a, b) => b.date.compareTo(a.date)); // descending by date
    return records;
  }

  Map<String, dynamic> getStudentStats({
    required String studentId,
    int? year,
    int? month,
    String? timing,
  }) {
    final records = getStudentAttendanceHistory(studentId: studentId, year: year, month: month, timing: timing);
    final totalClasses = records.length;
    final presentCount = records.where((r) => r.isPresent).length;
    final absentCount = records.where((r) => r.isAbsent).length;
    final double percentage = totalClasses > 0 ? (presentCount / totalClasses) * 100.0 : 0.0;

    return {
      'totalClasses': totalClasses,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'percentage': percentage,
      'records': records,
    };
  }

  Map<String, dynamic> getTodayOverallSummary() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int present = 0;
    int absent = 0;

    for (var record in _attendanceRepo.getAttendanceRecordMap().values) {
      if (record.date == todayStr) {
        if (record.isPresent) present++;
        if (record.isAbsent) absent++;
      }
    }

    return {
      'date': todayStr,
      'present': present,
      'absent': absent,
      'totalMarked': present + absent,
      'totalStudents': getAllStudents().length,
    };
  }

  Map<String, dynamic> getClassMonthlyReport({
    required String team,
    required String timing,
    required int year,
    required int month,
  }) {
    final students = getStudentsByGroup(team: team, timing: timing, includeInactive: true);
    final List<Map<String, dynamic>> studentReports = [];

    int totalClassPresents = 0;
    int totalClassAbsents = 0;

    for (var s in students) {
      final stats = getStudentStats(studentId: s.id, year: year, month: month, timing: timing);
      final int present = stats['presentCount'] as int;
      final int absent = stats['absentCount'] as int;
      final int total = stats['totalClasses'] as int;
      final double pct = stats['percentage'] as double;

      totalClassPresents += present;
      totalClassAbsents += absent;

      studentReports.add({
        'student': s,
        'present': present,
        'absent': absent,
        'total': total,
        'percentage': pct,
      });
    }

    final totalClassEntries = totalClassPresents + totalClassAbsents;
    final double classAvgPercentage =
        totalClassEntries > 0 ? (totalClassPresents / totalClassEntries) * 100.0 : 0.0;

    return {
      'team': team,
      'timing': timing,
      'year': year,
      'month': month,
      'students': studentReports,
      'totalPresents': totalClassPresents,
      'totalAbsents': totalClassAbsents,
      'averagePercentage': classAvgPercentage,
    };
  }
}
