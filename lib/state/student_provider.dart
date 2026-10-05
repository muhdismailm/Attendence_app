import 'dart:async';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../services/parent_account_service.dart';
import 'attendance_provider.dart';
import 'auth_provider.dart';

class StudentProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final FirebaseService _firebaseService;
  final ParentAccountService _parentAccountService;
  AttendanceProvider? _attendanceProvider;

  String _searchQuery = '';
  String _selectedTeamFilter = 'all'; // 'all' or team id
  String _selectedTimingFilter = 'all'; // 'all', 'morning', 'evening'
  bool _showInactiveOnly = false;
  bool _isLoading = false;

  List<Student> _students = [];
  String? _currentTutorId;
  StreamSubscription? _studentSubscription;

  StudentProvider(
    this._dbService,
    this._firebaseService, [
    ParentAccountService? parentAccountService,
  ]) : _parentAccountService = parentAccountService ?? ParentAccountService();

  void updateAttendanceProvider(AttendanceProvider attProv) {
    _attendanceProvider = attProv;
  }

  void updateAuthProvider(AuthProvider auth) {
    final newId = auth.currentUser?.id;
    if (_currentTutorId != newId) {
      _currentTutorId = newId;
      _initStudentStream();
    }
  }

  void _initStudentStream() {
    _studentSubscription?.cancel();
    if (_currentTutorId == null) {
      _students = [];
      notifyListeners();
      return;
    }
    
    _studentSubscription = _firebaseService.streamStudents(_currentTutorId!).listen((students) {
      _students = students;
      notifyListeners();
    });
  }

  void reinitializeStream() {
    _initStudentStream();
  }

  @override
  void dispose() {
    _studentSubscription?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedTeamFilter => _selectedTeamFilter;
  String get selectedTimingFilter => _selectedTimingFilter;
  bool get showInactiveOnly => _showInactiveOnly;

  List<Team> get teams => _dbService.getAllTeams();
  String getTeamName(String teamId) => _dbService.getTeamName(teamId);

  List<Student> get allStudents => List.unmodifiable(_students);
  List<Student> get activeStudents => _students.where((s) => s.active).toList();

  List<Student> get filteredStudents {
    final query = _searchQuery.trim().toLowerCase();

    return allStudents.where((student) {
      // Inactive filter
      if (!_showInactiveOnly && !student.active) return false;
      if (_showInactiveOnly && student.active) return false;

      // Team filter
      if (_selectedTeamFilter != 'all' && student.team.toLowerCase() != _selectedTeamFilter.toLowerCase()) {
        return false;
      }

      // Search Query
      if (query.isNotEmpty) {
        final nameMatch = student.name.toLowerCase().contains(query);
        final rollMatch = student.rollNumber.toLowerCase().contains(query);
        final parentMatch = student.parentName.toLowerCase().contains(query);
        final placeMatch = student.place != null && student.place!.toLowerCase().contains(query);
        if (!nameMatch && !rollMatch && !parentMatch && !placeMatch) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Sort by team, then rollNumber
        final teamComp = a.team.compareTo(b.team);
        if (teamComp != 0) return teamComp;
        return a.rollNumber.compareTo(b.rollNumber);
      });
  }

  int getGroupStudentCount(String team, String timing) {
    return _students.where((s) {
      return s.team.toLowerCase() == team.toLowerCase() && s.active;
    }).length;
  }

  int getTeamTotalStudentCount(String team) {
    return _students.where((s) {
      return s.team.toLowerCase() == team.toLowerCase() && s.active;
    }).length;
  }

  List<Student> getStudentsForTeam(String team) {
    var result = _students.where((s) {
      return s.team.toLowerCase() == team.toLowerCase() && s.active;
    }).toList();
    result.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
    return result;
  }

  List<Student> getStudentsForGroup(String team, String timing) {
    var result = _students.where((s) {
      return s.team.toLowerCase() == team.toLowerCase() && s.active;
    }).toList();
    result.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
    return result;
  }

  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Student? getStudentByRollNo(String rollNo) {
    try {
      return _students.firstWhere((s) => s.rollNumber.trim() == rollNo.trim());
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTeamFilter(String team) {
    _selectedTeamFilter = team;
    notifyListeners();
  }

  void setTimingFilter(String timing) {
    _selectedTimingFilter = timing;
    notifyListeners();
  }

  void toggleInactiveFilter() {
    _showInactiveOnly = !_showInactiveOnly;
    notifyListeners();
  }

  Future<void> addStudent(Student student) async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.addStudent(student);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.updateStudent(student);

    _isLoading = false;
    notifyListeners();
  }

  Future<StudentDeletionReport> deleteStudent(
    String studentId, [
    AttendanceProvider? attendanceProvider,
  ]) async {
    final attProv = attendanceProvider ?? _attendanceProvider;

    // 1. Disable "Sync Now" and auto-refreshes while deletion runs
    attProv?.setStudentDeletionInProgress(true);
    _isLoading = true;
    notifyListeners();

    try {
      // Steps 1 to 5: Cloud cascade deletion via service layer
      final report = await _firebaseService.deleteStudentCompletely(studentId);

      // Step 6: Purge local data ONLY after all cloud steps succeed:
      // Purge all local attendance records (synced and pending) from Hive,
      // and remove student from local cached student data.
      await _dbService.deleteStudentCompletelyLocal(studentId);

      // Step 7: Clear this student's records from AttendanceProvider in-memory state
      attProv?.clearStudentAttendanceFromMemory(studentId);

      // Update StudentProvider in-memory state
      _students.removeWhere((s) => s.id == studentId);
      _isLoading = false;
      notifyListeners();

      return report;
    } finally {
      // Re-enable sync operations
      attProv?.setStudentDeletionInProgress(false);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleActiveStatus(String studentId) async {
    final student = getStudentById(studentId);
    if (student != null) {
      await _firebaseService.updateStudent(student.copyWith(active: !student.active));
    }
  }

  // ==================== TEAM MANAGEMENT ====================

  Future<Team> createTeam({
    required String name,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newTeam = Team(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description?.trim(),
      createdAt: DateTime.now(),
    );

    final created = await _dbService.addTeam(newTeam);

    _isLoading = false;
    notifyListeners();
    return created;
  }

  Future<void> updateTeam(Team team) async {
    _isLoading = true;
    notifyListeners();

    await _dbService.updateTeam(team);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTeam(String teamId) async {
    _isLoading = true;
    notifyListeners();

    await _dbService.deleteTeam(teamId);

    if (_selectedTeamFilter.toLowerCase() == teamId.toLowerCase()) {
      _selectedTeamFilter = 'all';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== PARENT ACCOUNT MANAGEMENT ====================

  /// Creates a parent account for a student. Returns loginId and pin for immediate one-time display.
  /// Does NOT cache or store PIN in provider state.
  Future<ParentCredentials> createParentAccount(Student student) async {
    final creds = await _parentAccountService.createParentAccount(student);
    return creds;
  }

  /// Issues a new parent login for a student: generates new credentials, deactivates old parent doc.
  /// Does NOT cache or store PIN in provider state.
  Future<ParentCredentials> issueNewParentLogin(Student student) async {
    final creds = await _parentAccountService.issueNewParentLogin(student);
    return creds;
  }

  /// Toggles the parent account active flag.
  Future<void> setParentActive(String parentUid, bool active) async {
    await _parentAccountService.setParentActive(parentUid, active);
  }

  /// Fetches the parent account details for a given parent UID.
  Future<AppUser?> getParentAccount(String parentUid) async {
    return await _parentAccountService.getParentAccount(parentUid);
  }

  /// Real-time stream of parent account details for a given parent UID.
  Stream<AppUser?> streamParentAccount(String parentUid) {
    return _parentAccountService.streamParentAccount(parentUid);
  }
}
