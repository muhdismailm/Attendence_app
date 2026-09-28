import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final FirestoreService _firestoreService;

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

      // 2. If there are no pending records: return successfully
      if (pendingRecords.isEmpty) {
        _pendingSyncCount = 0;
        _isSyncing = false;
        _syncSuccessMessage = 'All attendance records are synchronized.';
        notifyListeners();
        return true;
      }

      // 3. Check internet connectivity
      final hasInternet = await _firestoreService.checkInternetConnection();
      if (!hasInternet) {
        _isSyncing = false;
        _syncError = 'No internet connection. ${pendingRecords.length} record(s) safely stored on this device.';
        _pendingSyncCount = pendingRecords.length;
        notifyListeners();
        return false;
      }

      // 4. If internet is available: upload every pending attendance record to Firestore
      final successfullySyncedIds = await _firestoreService.syncPendingBatch(pendingRecords);

      // 5. After successful Firestore upload: change local record syncStatus = 'synced'
      if (successfullySyncedIds.isNotEmpty) {
        await _dbService.attendanceRepo.markRecordsAsSynced(successfullySyncedIds);
      }

      // 6. Refresh pending count
      _pendingSyncCount = _dbService.attendanceRepo.getPendingCount();
      _lastSyncTime = DateTime.now();

      if (_pendingSyncCount == 0) {
        _syncSuccessMessage = 'Attendance synced successfully (${successfullySyncedIds.length} records).';
        _syncError = null;
      } else {
        _syncError = '$_pendingSyncCount attendance record(s) could not be synced. They remain safely stored on this device.';
      }

      _isSyncing = false;
      notifyListeners();
      return _pendingSyncCount == 0;
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
