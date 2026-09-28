class Team {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Team(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt']) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Team copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
