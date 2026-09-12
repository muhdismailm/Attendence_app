class AttendanceRecord {
  final String id;
  final String studentId;
  final String date; // Format: YYYY-MM-DD
  final String status; // 'present' or 'absent'
  final String markedBy;
  final String? team;
  final String? timing;
  final DateTime? timestamp;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.team,
    this.timing,
    this.timestamp,
  });

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
      'markedBy': markedBy,
      'team': team,
      'timing': timing,
      'timestamp': timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parsedTime;
    if (map['timestamp'] != null) {
      if (map['timestamp'] is String) {
        parsedTime = DateTime.tryParse(map['timestamp']);
      } else if (map['timestamp'] is int) {
        parsedTime = DateTime.fromMillisecondsSinceEpoch(map['timestamp']);
      }
    }

    return AttendanceRecord(
      id: docId ?? map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'present',
      markedBy: map['markedBy'] ?? '',
      team: map['team'],
      timing: map['timing'],
      timestamp: parsedTime,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? date,
    String? status,
    String? markedBy,
    String? team,
    String? timing,
    DateTime? timestamp,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      team: team ?? this.team,
      timing: timing ?? this.timing,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
