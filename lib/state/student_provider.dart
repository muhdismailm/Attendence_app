import 'dart:async';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';

class StudentProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final FirebaseService _firebaseService;

  String _searchQuery = '';
  String _selectedTeamFilter = 'all'; // 'all' or team id
  String _selectedTimingFilter = 'all'; // 'all', 'morning', 'evening'
  bool _showInactiveOnly = false;
  bool _isLoading = false;

  List<Student> _students = [];
  StreamSubscription? _studentSubscription;
  StreamSubscription? _authSubscription;

  StudentProvider(this._dbService, this._firebaseService) {
    _authSubscription = _firebaseService.auth.authStateChanges().listen((user) {
      if (user != null) {
        _initStudentStream();
      } else {
        clearStudents();
      }
    });
    _initStudentStream();
  }

  void _initStudentStream() {
    _studentSubscription?.cancel();
    _studentSubscription = _firebaseService.streamStudents().listen((students) {
      _students = students;
      notifyListeners();
    });
  }

  void clearStudents() {
    _studentSubscription?.cancel();
    _students = [];
    notifyListeners();
  }

  void reinitializeStream() {
    _initStudentStream();
  }

  @override
  void dispose() {
    _studentSubscription?.cancel();
    _authSubscription?.cancel();
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

  Future<void> deleteStudent(String studentId) async {
    _isLoading = true;
    notifyListeners();

    await _firebaseService.deleteStudent(studentId);

    _isLoading = false;
    notifyListeners();
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
}
