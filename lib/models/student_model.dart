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
  final bool active;

  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.team,
    required this.timing,
    this.parentId,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    this.active = true,
  });

  String get teamDisplayName => team == 'team1' ? 'Team 1' : 'Team 2';
  String get timingDisplayName => 'Morning & Evening';
  String get groupKey => team;
  String get groupDisplayName => '$teamDisplayName • Morning & Evening';

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
      'active': active,
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
      active: map['active'] ?? true,
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
    bool? active,
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
      active: active ?? this.active,
    );
  }
}
