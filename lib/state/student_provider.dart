import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';

class StudentProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  String _searchQuery = '';
  String _selectedTeamFilter = 'all'; // 'all', 'team1', 'team2'
  String _selectedTimingFilter = 'all'; // 'all', 'morning', 'evening'
  bool _showInactiveOnly = false;
  bool _isLoading = false;

  StudentProvider(this._dbService);

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedTeamFilter => _selectedTeamFilter;
  String get selectedTimingFilter => _selectedTimingFilter;
  bool get showInactiveOnly => _showInactiveOnly;

  List<Student> get allStudents => _dbService.getAllStudents(includeInactive: true);
  List<Student> get activeStudents => _dbService.getAllStudents(includeInactive: false);

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
        if (!nameMatch && !rollMatch && !parentMatch) return false;
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
    return _dbService.getStudentsByGroup(team: team, timing: timing, includeInactive: false).length;
  }

  int getTeamTotalStudentCount(String team) {
    return _dbService.getStudentsByTeam(team: team, includeInactive: false).length;
  }

  List<Student> getStudentsForTeam(String team) {
    return _dbService.getStudentsByTeam(team: team, includeInactive: false);
  }

  List<Student> getStudentsForGroup(String team, String timing) {
    return _dbService.getStudentsByGroup(team: team, timing: timing, includeInactive: false);
  }

  Student? getStudentById(String id) {
    return _dbService.getStudentById(id);
  }

  Student? getStudentByRollNo(String rollNo) {
    try {
      return allStudents.firstWhere((s) => s.rollNumber.trim() == rollNo.trim());
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

    await _dbService.addStudent(student);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStudent(Student student) async {
    _isLoading = true;
    notifyListeners();

    await _dbService.updateStudent(student);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleActiveStatus(String studentId) async {
    await _dbService.toggleStudentActive(studentId);
    notifyListeners();
  }
}
