import 'attendance_model.dart';

class AttendanceLocal {
  final String id;
  final String studentId;
  final String date; // Normalized format: YYYY-MM-DD
  final String status; // 'present' or 'absent'
  final String syncStatus; // 'pending' or 'synced'
  final DateTime createdAt;
  final String? markedBy;
  final String? team;
  final String? timing;

  const AttendanceLocal({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    this.syncStatus = 'pending',
    required this.createdAt,
    this.markedBy,
    this.team,
    this.timing,
  });

  bool get isPending => syncStatus == 'pending';
  bool get isSynced => syncStatus == 'synced';
  bool get isPresent => status.toLowerCase() == 'present';
  bool get isAbsent => status.toLowerCase() == 'absent';

  static String generateId(String studentId, String date, [String? timing]) {
    if (timing != null && timing.isNotEmpty) {
      return '${studentId}_${date}_$timing';
    }
    return '${studentId}_$date';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date,
      'status': status,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'markedBy': markedBy,
      'team': team,
      'timing': timing,
    };
  }

  /// Map suitable for uploading directly to Firestore attendance document
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'studentId': studentId,
      'date': date,
      'status': status,
      'markedBy': markedBy ?? '',
      'team': team,
      'timing': timing,
      'timestamp': createdAt.toIso8601String(),
    };
  }

  factory AttendanceLocal.fromMap(Map<dynamic, dynamic> map, {String? docId}) {
    DateTime? parsedCreated;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        parsedCreated = DateTime.tryParse(map['createdAt']);
      } else if (map['createdAt'] is int) {
        parsedCreated = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
      }
    }

    return AttendanceLocal(
      id: docId ?? map['id']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'present',
      syncStatus: map['syncStatus']?.toString() ?? 'pending',
      createdAt: parsedCreated ?? DateTime.now(),
      markedBy: map['markedBy']?.toString(),
      team: map['team']?.toString(),
      timing: map['timing']?.toString(),
    );
  }

  AttendanceLocal copyWith({
    String? id,
    String? studentId,
    String? date,
    String? status,
    String? syncStatus,
    DateTime? createdAt,
    String? markedBy,
    String? team,
    String? timing,
  }) {
    return AttendanceLocal(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      markedBy: markedBy ?? this.markedBy,
      team: team ?? this.team,
      timing: timing ?? this.timing,
    );
  }

  AttendanceRecord toAttendanceRecord() {
    return AttendanceRecord(
      id: id,
      studentId: studentId,
      date: date,
      status: status,
      markedBy: markedBy ?? '',
      team: team,
      timing: timing,
      timestamp: createdAt,
    );
  }

  factory AttendanceLocal.fromAttendanceRecord(AttendanceRecord record, {String syncStatus = 'pending'}) {
    return AttendanceLocal(
      id: record.id,
      studentId: record.studentId,
      date: record.date,
      status: record.status,
      syncStatus: syncStatus,
      createdAt: record.timestamp ?? DateTime.now(),
      markedBy: record.markedBy,
      team: record.team,
      timing: record.timing,
    );
  }
}
