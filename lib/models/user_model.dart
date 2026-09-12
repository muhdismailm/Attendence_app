class AppUser {
  final String id;
  final String username;
  final String pin; // 4-digit PIN/password
  final String name;
  final String role; // 'tutor' or 'parent'
  final String? studentId; // If parent, linked student ID
  final String? studentRollNo; // For display/linking
  final String? phone;

  const AppUser({
    required this.id,
    required this.username,
    required this.pin,
    required this.name,
    required this.role,
    this.studentId,
    this.studentRollNo,
    this.phone,
  });

  bool get isTutor => role == 'tutor';
  bool get isParent => role == 'parent';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username.trim().toLowerCase(),
      'pin': pin,
      'name': name,
      'role': role,
      'studentId': studentId,
      'studentRollNo': studentRollNo,
      'phone': phone,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppUser(
      id: docId ?? map['id'] ?? '',
      username: map['username'] ?? '',
      pin: map['pin'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'parent',
      studentId: map['studentId'],
      studentRollNo: map['studentRollNo'],
      phone: map['phone'],
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
    );
  }
}
