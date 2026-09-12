import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  DateTime _selectedDate = DateTime.now();
  String _activeTeam = 'team1';
  String _activeTiming = 'morning';

  // In-memory status map during marking session: studentId -> 'present' | 'absent'
  final Map<String, String> _currentMarkingState = {};
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  AttendanceProvider(this._dbService);

  DateTime get selectedDate => _selectedDate;
  String get selectedDateFormatted => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get selectedDateDisplay => DateFormat('MMMM d, yyyy').format(_selectedDate);

  String get activeTeam => _activeTeam;
  String get activeTiming => _activeTiming;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  Map<String, String> get currentMarkingState => Map.unmodifiable(_currentMarkingState);
  Map<String, AttendanceRecord> get allAttendanceMap => _dbService.allAttendanceMap;


  // Initialize marking screen for a specific group and date
  void initMarkingSession({
    required String team,
    required String timing,
    DateTime? date,
  }) {
    _activeTeam = team;
    _activeTiming = timing;
    if (date != null) {
      _selectedDate = date;
    }

    final dateStr = selectedDateFormatted;
    final existingMap = _dbService.getAttendanceForDateAndGroup(
      date: dateStr,
      team: team,
      timing: timing,
    );

    final students = _dbService.getStudentsByGroup(
      team: team,
      timing: timing,
      includeInactive: false,
    );

    _currentMarkingState.clear();

    if (existingMap.isNotEmpty) {
      // Load existing records
      for (var s in students) {
        if (existingMap.containsKey(s.id)) {
          _currentMarkingState[s.id] = existingMap[s.id]!.status;
        } else {
          _currentMarkingState[s.id] = 'present'; // Default for new student
        }
      }
    } else {
      // Default all to 'present' so tutor only toggles the few absentees
      for (var s in students) {
        _currentMarkingState[s.id] = 'present';
      }
    }

    _hasUnsavedChanges = false;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    initMarkingSession(team: _activeTeam, timing: _activeTiming, date: date);
  }

  void setStudentStatus(String studentId, String status) {
    if (_currentMarkingState[studentId] != status) {
      _currentMarkingState[studentId] = status;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void toggleStudentStatus(String studentId) {
    final current = _currentMarkingState[studentId] ?? 'present';
    final next = current == 'present' ? 'absent' : 'present';
    _currentMarkingState[studentId] = next;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void markAllPresent(List<Student> students) {
    for (var s in students) {
      _currentMarkingState[s.id] = 'present';
    }
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void markAllAbsent(List<Student> students) {
    for (var s in students) {
      _currentMarkingState[s.id] = 'absent';
    }
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  int get presentCountInSession =>
      _currentMarkingState.values.where((status) => status == 'present').length;

  int get absentCountInSession =>
      _currentMarkingState.values.where((status) => status == 'absent').length;

  Future<bool> saveAttendance({
    required List<Student> students,
    required String tutorId,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final dateStr = selectedDateFormatted;
      final List<AttendanceRecord> recordsToSave = [];

      for (var s in students) {
        final status = _currentMarkingState[s.id] ?? 'present';
        final recordId = AttendanceRecord.generateId(s.id, dateStr, _activeTiming);

        recordsToSave.add(
          AttendanceRecord(
            id: recordId,
            studentId: s.id,
            date: dateStr,
            status: status,
            markedBy: tutorId,
            team: s.team,
            timing: _activeTiming,
            timestamp: DateTime.now(),
          ),
        );
      }

      await _dbService.saveAttendanceBatch(recordsToSave);

      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Summary & Reports
  Map<String, dynamic> getTodaySummary() {
    return _dbService.getTodayOverallSummary();
  }

  Map<String, dynamic> getStudentStats(String studentId, {int? year, int? month, String? timing}) {
    return _dbService.getStudentStats(studentId: studentId, year: year, month: month, timing: timing);
  }

  List<AttendanceRecord> getStudentAttendanceHistory(String studentId, {int? year, int? month, String? timing}) {
    return _dbService.getStudentAttendanceHistory(studentId: studentId, year: year, month: month, timing: timing);
  }

  Map<String, dynamic> getClassMonthlyReport({
    required String team,
    required String timing,
    required int year,
    required int month,
  }) {
    return _dbService.getClassMonthlyReport(
      team: team,
      timing: timing,
      year: year,
      month: month,
    );
  }
}
