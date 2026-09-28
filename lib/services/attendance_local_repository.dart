import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance_local.dart';
import '../models/attendance_model.dart';

class AttendanceLocalRepository {
  static const String boxName = 'attendance_records_box_v1';
  Box<Map>? _box;

  Box<Map> get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError('Attendance local database is not initialized yet.');
    }
    return _box!;
  }

  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;

    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(boxName);
  }

  /// Get total count of attendance records currently marked as pending sync
  int getPendingCount() {
    if (_box == null || !_box!.isOpen) return 0;
    int count = 0;
    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        final syncStatus = raw['syncStatus']?.toString() ?? 'pending';
        if (syncStatus == 'pending') {
          count++;
        }
      }
    }
    return count;
  }

  /// Retrieve all pending attendance records across all dates
  List<AttendanceLocal> getPendingRecords() {
    if (_box == null || !_box!.isOpen) return [];
    final List<AttendanceLocal> pending = [];
    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        final record = AttendanceLocal.fromMap(raw);
        if (record.isPending) {
          pending.add(record);
        }
      }
    }
    // Sort chronologically by date and creation time
    pending.sort((a, b) => a.date.compareTo(b.date));
    return pending;
  }

  /// Retrieve all local records
  List<AttendanceLocal> getAllRecords() {
    if (_box == null || !_box!.isOpen) return [];
    final List<AttendanceLocal> list = [];
    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        list.add(AttendanceLocal.fromMap(raw));
      }
    }
    return list;
  }

  /// Map of recordId -> AttendanceLocal
  Map<String, AttendanceLocal> getAttendanceMap() {
    if (_box == null || !_box!.isOpen) return {};
    final Map<String, AttendanceLocal> map = {};
    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        final item = AttendanceLocal.fromMap(raw);
        map[item.id] = item;
      }
    }
    return map;
  }

  /// Map of recordId -> AttendanceRecord for backwards compatibility
  Map<String, AttendanceRecord> getAttendanceRecordMap() {
    if (_box == null || !_box!.isOpen) return {};
    final Map<String, AttendanceRecord> map = {};
    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        final item = AttendanceLocal.fromMap(raw);
        map[item.id] = item.toAttendanceRecord();
      }
    }
    return map;
  }

  /// Save or update a single record (marks as pending if updated offline)
  Future<void> saveRecord(AttendanceLocal record) async {
    await _safeBox.put(record.id, record.toMap());
  }

  /// Batch save local records (idempotent overwrite by recordId)
  Future<void> saveRecordsBatch(List<AttendanceLocal> records) async {
    final Map<String, Map> entries = {};
    for (var r in records) {
      entries[r.id] = r.toMap();
    }
    await _safeBox.putAll(entries);
  }

  /// Mark a single record as synced
  Future<void> markRecordAsSynced(String recordId) async {
    final raw = _safeBox.get(recordId);
    if (raw != null) {
      final updated = Map<dynamic, dynamic>.from(raw);
      updated['syncStatus'] = 'synced';
      await _safeBox.put(recordId, updated);
    }
  }

  /// Mark a list of record IDs as synced in a single batch
  Future<void> markRecordsAsSynced(List<String> recordIds) async {
    final Map<String, Map> updates = {};
    for (var id in recordIds) {
      final raw = _safeBox.get(id);
      if (raw != null) {
        final updated = Map<dynamic, dynamic>.from(raw);
        updated['syncStatus'] = 'synced';
        updates[id] = updated;
      }
    }
    if (updates.isNotEmpty) {
      await _safeBox.putAll(updates);
    }
  }

  /// Delete records for student or team (cascade support)
  Future<void> deleteRecordsForStudentOrTeam({
    Set<String>? studentIds,
    String? team,
  }) async {
    final keysToDelete = <dynamic>[];
    final teamKey = team?.toLowerCase();

    for (var key in _safeBox.keys) {
      final raw = _safeBox.get(key);
      if (raw != null) {
        final sId = raw['studentId']?.toString();
        final t = raw['team']?.toString().toLowerCase();

        final matchesStudent = studentIds != null && sId != null && studentIds.contains(sId);
        final matchesTeam = teamKey != null && t == teamKey;

        if (matchesStudent || matchesTeam) {
          keysToDelete.add(key);
        }
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _safeBox.deleteAll(keysToDelete);
    }
  }

  /// Seed initial sample attendance if repository is brand new
  Future<void> seedInitialDataIfEmpty(List<AttendanceRecord> initialRecords) async {
    if (_safeBox.isEmpty && initialRecords.isNotEmpty) {
      final Map<String, Map> entries = {};
      for (var r in initialRecords) {
        final local = AttendanceLocal.fromAttendanceRecord(r, syncStatus: 'synced');
        entries[local.id] = local.toMap();
      }
      await _safeBox.putAll(entries);
    }
  }

  Future<void> clearAll() async {
    await _safeBox.clear();
  }
}
