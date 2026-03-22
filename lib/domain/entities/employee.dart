class Employee {
  final String id;
  final String name;
  final String companyId;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.name,
    required this.companyId,
    required this.createdAt,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? companyId,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          companyId == other.companyId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, name, companyId, createdAt);
}
