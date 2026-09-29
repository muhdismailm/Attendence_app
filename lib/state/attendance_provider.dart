import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import 'student_provider.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final FirestoreService _firestoreService;
  StudentProvider? _studentProvider;

  DateTime _selectedDate = DateTime.now();
  String _activeTeam = 'team1';
  String _activeTiming = 'morning';

  // In-memory status map during marking session: studentId -> 'present' | 'absent'
  final Map<String, String> _currentMarkingState = {};
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  // Sync state
  int _pendingSyncCount = 0;
  bool _isSyncing = false;
  String? _syncError;
  String? _syncSuccessMessage;
  DateTime? _lastSyncTime;

  AttendanceProvider(
    this._dbService, [
    FirestoreService? firestoreService,
  ]) : _firestoreService = firestoreService ?? FirestoreService() {
    loadPendingSyncCount();
    // Attempt background sync on app start if pending items exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingSyncCount > 0) {
        syncPendingAttendance(isManual: false);
      }
    });
  }

  void updateStudentProvider(StudentProvider provider) {
    _studentProvider = provider;
  }

  DateTime get selectedDate => _selectedDate;
  String get selectedDateFormatted => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get selectedDateDisplay => DateFormat('MMMM d, yyyy').format(_selectedDate);

  String get activeTeam => _activeTeam;
  String get activeTiming => _activeTiming;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  Map<String, String> get currentMarkingState => Map.unmodifiable(_currentMarkingState);
  Map<String, AttendanceRecord> get allAttendanceMap => _dbService.allAttendanceMap;

  // Sync Getters
  int get pendingSyncCount => _pendingSyncCount;
  bool get isSyncing => _isSyncing;
  String? get syncError => _syncError;
  String? get syncSuccessMessage => _syncSuccessMessage;
  DateTime? get lastSyncTime => _lastSyncTime;

  // ==================== SYNC FUNCTIONS ====================

  /// Load count of all attendance records needing sync from local database
  Future<void> loadPendingSyncCount() async {
    _pendingSyncCount = _dbService.attendanceRepo.getPendingCount();
    notifyListeners();
  }

  /// Refresh sync status and pending count
  Future<void> refreshSyncStatus() async {
    await loadPendingSyncCount();
  }

  void clearSyncMessages() {
    _syncError = null;
    _syncSuccessMessage = null;
    notifyListeners();
  }

  /// Core Sync Function: Synchronizes all pending local attendance records to Firestore.
  /// Works across all dates, idempotent using .doc(id).set(...), never loses local data.
  Future<bool> syncPendingAttendance({bool isManual = true}) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _syncError = null;
    _syncSuccessMessage = null;
    notifyListeners();

    try {
      // 1. Read all local attendance records where syncStatus == 'pending'
      final pendingRecords = _dbService.attendanceRepo.getPendingRecords();

      // Verify student belongs to currently authenticated tutor
      final allStudents = _studentProvider?.allStudents ?? [];
      final validStudentIds = allStudents.map((s) => s.id).toSet();
      final recordsToSync = pendingRecords.where((r) => validStudentIds.contains(r.studentId)).toList();

      // 2. If there are no pending records: return successfully
      if (recordsToSync.isEmpty) {
        // If there are pending records but none for the current tutor, just say nothing to sync
        if (pendingRecords.isEmpty) {
          _pendingSyncCount = 0;
        }
        _isSyncing = false;
        _syncSuccessMessage = 'All attendance records are synchronized.';
        notifyListeners();
        return true;
      }

      // 3. Check internet connectivity
      final hasInternet = await _firestoreService.checkInternetConnection();
      if (!hasInternet) {
        _isSyncing = false;
        _syncError = 'No internet connection. ${recordsToSync.length} record(s) safely stored on this device.';
        _pendingSyncCount = pendingRecords.length; // Keep global pending count
        notifyListeners();
        return false;
      }

      // 4. If internet is available: upload every pending attendance record to Firestore
      final successfullySyncedIds = await _firestoreService.syncPendingBatch(recordsToSync);

      // 5. After successful Firestore upload: change local record syncStatus = 'synced'
      if (successfullySyncedIds.isNotEmpty) {
        await _dbService.attendanceRepo.markRecordsAsSynced(successfullySyncedIds);
      }

      // 6. Refresh pending count
      _pendingSyncCount = _dbService.attendanceRepo.getPendingCount();
      _lastSyncTime = DateTime.now();

      if (_pendingSyncCount == 0 || successfullySyncedIds.length == recordsToSync.length) {
        _syncSuccessMessage = 'Attendance synced successfully (${successfullySyncedIds.length} records).';
        _syncError = null;
      } else {
        _syncError = 'Some attendance record(s) could not be synced. They remain safely stored on this device.';
      }

      _isSyncing = false;
      notifyListeners();
      return successfullySyncedIds.length == recordsToSync.length;
    } catch (e) {
      _pendingSyncCount = _dbService.attendanceRepo.getPendingCount();
      _syncError = 'Some attendance records could not be synced. They are safely stored on this device.';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== MARKING SESSION ====================

  /// Initialize marking screen for a specific group and date
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
    
    final students = _studentProvider?.getStudentsForGroup(team, timing) ?? [];
    
    // We can't use DatabaseService's existing group filter because it uses SharedPreferences
    // So we just iterate over students and check the hive local DB
    final attMap = _dbService.attendanceRepo.getAttendanceRecordMap();
    final Map<String, AttendanceRecord> existingMap = {};
    for (var s in students) {
      final docIdWithTiming = AttendanceRecord.generateId(s.id, dateStr, timing);
      final docIdLegacy = AttendanceRecord.generateId(s.id, dateStr);
      if (attMap.containsKey(docIdWithTiming)) {
        existingMap[s.id] = attMap[docIdWithTiming]!;
      } else if (attMap.containsKey(docIdLegacy) && attMap[docIdLegacy]?.timing == timing) {
        existingMap[s.id] = attMap[docIdLegacy]!;
      }
    }

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

  /// Offline-First save:
  /// 1. Saves directly to local Hive database (marked as 'pending')
  /// 2. Updates local pending counter
  /// 3. Attempts automatic background sync if online
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

      // 1. Save to local database with syncStatus: 'pending'
      await _dbService.saveAttendanceBatch(recordsToSave, syncStatus: 'pending');

      // 2. Update pending count immediately
      _pendingSyncCount = _dbService.attendanceRepo.getPendingCount();

      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();

      // 3. Trigger background sync immediately (non-blocking)
      syncPendingAttendance(isManual: false);

      return true;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== SUMMARY & REPORTS ====================

  Map<String, dynamic> getTodaySummary() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int present = 0;
    int absent = 0;

    final allStudents = _studentProvider?.allStudents ?? [];
    final validStudentIds = allStudents.map((s) => s.id).toSet();

    for (var record in _dbService.attendanceRepo.getAttendanceRecordMap().values) {
      if (record.date == todayStr && validStudentIds.contains(record.studentId)) {
        if (record.isPresent) present++;
        if (record.isAbsent) absent++;
      }
    }

    return {
      'date': todayStr,
      'present': present,
      'absent': absent,
      'totalMarked': present + absent,
      'totalStudents': allStudents.length,
    };
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
    final students = _studentProvider?.allStudents.where((s) => s.team.toLowerCase() == team.toLowerCase()).toList() ?? [];
    final List<Map<String, dynamic>> studentReports = [];

    int totalClassPresents = 0;
    int totalClassAbsents = 0;

    for (var s in students) {
      final stats = getStudentStats(s.id, year: year, month: month, timing: timing);
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
