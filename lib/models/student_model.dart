import 'package:intl/intl.dart';

class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String team; // 'team1' or 'team2'
  final String timing; // 'morning' or 'evening'
  final String? parentId;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final String? place;
  final String? secondaryPhone;
  final bool active;
  final String? tutorId;
  final String? address;
  final String? dob;
  final String? admissionDate;
  final String? skills;

  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.team,
    required this.timing,
    this.parentId,
    required this.parentName,
    required this.parentPhone,
    this.parentEmail = '',
    this.place,
    this.secondaryPhone,
    this.active = true,
    this.tutorId,
    this.address,
    this.dob,
    this.admissionDate,
    this.skills,
  });

  String get teamDisplayName => team == 'team1' ? 'Team 1' : 'Team 2';
  String get timingDisplayName => 'Morning & Evening';
  String get groupKey => team;
  String get groupDisplayName => '$teamDisplayName • Morning & Evening';

  /// Calculates student age based on dob
  int? get age {
    if (dob == null || dob!.trim().isEmpty) return null;
    DateTime? parsed;
    try {
      parsed = DateFormat('dd MMM yyyy').parse(dob!.trim());
    } catch (_) {
      try {
        parsed = DateTime.parse(dob!.trim());
      } catch (_) {}
    }
    if (parsed == null) return null;
    final now = DateTime.now();
    int calculated = now.year - parsed.year;
    if (now.month < parsed.month || (now.month == parsed.month && now.day < parsed.day)) {
      calculated--;
    }
    return calculated >= 0 ? calculated : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'team': team,
      'timing': timing,
      'parentId': parentId,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'parentEmail': parentEmail,
      'place': place,
      'secondaryPhone': secondaryPhone,
      'active': active,
      'tutorId': tutorId,
      'address': address,
      'dob': dob,
      'admissionDate': admissionDate,
      'skills': skills,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Student(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      team: map['team'] ?? 'team1',
      timing: map['timing'] ?? 'morning',
      parentId: map['parentId'],
      parentName: map['parentName'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      parentEmail: map['parentEmail'] ?? '',
      place: map['place'],
      secondaryPhone: map['secondaryPhone'],
      active: map['active'] ?? true,
      tutorId: map['tutorId'],
      address: map['address'],
      dob: map['dob'] ?? map['dateOfBirth'],
      admissionDate: map['admissionDate'],
      skills: map['skills'],
    );
  }

  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? team,
    String? timing,
    String? parentId,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? place,
    String? secondaryPhone,
    bool? active,
    String? tutorId,
    String? address,
    String? dob,
    String? admissionDate,
    String? skills,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      team: team ?? this.team,
      timing: timing ?? this.timing,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      place: place ?? this.place,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      active: active ?? this.active,
      tutorId: tutorId ?? this.tutorId,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      admissionDate: admissionDate ?? this.admissionDate,
      skills: skills ?? this.skills,
    );
  }
}
