class AppUser {
  final String id;
  final String username;
  final String pin; // Kept for backward compatibility with dialogs/mocks
  final String name;
  final String role; // 'tutor' or 'parent'
  final String? studentId; // If parent, linked student ID
  final String? studentRollNo; // For display/linking
  final String? phone;
  final String? place;
  final bool active;

  const AppUser({
    required this.id,
    required this.username,
    this.pin = '',
    required this.name,
    required this.role,
    this.studentId,
    this.studentRollNo,
    this.phone,
    this.place,
    this.active = true,
  });

  bool get isTutor => role.toLowerCase() == 'tutor';
  bool get isParent => role.toLowerCase() == 'parent';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username.trim().toLowerCase(),
      'name': name,
      'role': role,
      'active': active,
      if (studentId != null) 'studentId': studentId,
      if (studentRollNo != null) 'studentRollNo': studentRollNo,
      if (phone != null) 'phone': phone,
      if (place != null) 'place': place,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppUser(
      id: docId ?? map['id'] ?? '',
      username: map['username'] ?? '',
      pin: map['pin'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'tutor',
      studentId: map['studentId'],
      studentRollNo: map['studentRollNo'],
      phone: map['phone'],
      place: map['place'],
      active: map['active'] ?? true,
    );
  }

  AppUser copyWith({
    String? id,
    String? username,
    String? pin,
    String? name,
    String? role,
    String? studentId,
    String? studentRollNo,
    String? phone,
    String? place,
    bool? active,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      name: name ?? this.name,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      studentRollNo: studentRollNo ?? this.studentRollNo,
      phone: phone ?? this.phone,
      place: place ?? this.place,
      active: active ?? this.active,
    );
  }
}
