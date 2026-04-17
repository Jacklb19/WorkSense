class Employee {
  final String id;
  final String name;
  final String companyId;
  final DateTime createdAt;
  final List<double>? faceEmbedding;

  const Employee({
    required this.id,
    required this.name,
    required this.companyId,
    required this.createdAt,
    this.faceEmbedding,
  });

  Employee copyWith({
    String? id,
    String? name,
    String? companyId,
    DateTime? createdAt,
    List<double>? faceEmbedding,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
      // El embedding se maneja fuera de esta entidad para serialización remota/local
      // siguiendo la arquitectura limpia sugerida en el roadmap.
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
          createdAt == other.createdAt &&
          faceEmbedding == other.faceEmbedding;

  @override
  int get hashCode => Object.hash(id, name, companyId, createdAt, faceEmbedding);
}

