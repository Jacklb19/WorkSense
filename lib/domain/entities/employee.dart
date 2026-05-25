import 'package:worksense_app/domain/entities/app_role.dart';

class Employee {
  static const Object _sentinel = Object();

  final String id;
  final String name;
  final String lastName;
  final String email;
  final AppRole role;
  final String companyId;
  final DateTime createdAt;
  final List<List<double>>? faceEmbeddings;
  final String? shiftId;

  const Employee({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
    required this.companyId,
    required this.createdAt,
    this.faceEmbeddings,
    this.shiftId,
  });

  String get displayName => [name, lastName]
      .where((part) => part.trim().isNotEmpty)
      .join(' ')
      .trim();

  Employee copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    AppRole? role,
    String? companyId,
    DateTime? createdAt,
    Object? faceEmbeddings = _sentinel,
    Object? shiftId = _sentinel,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      faceEmbeddings: identical(faceEmbeddings, _sentinel)
          ? this.faceEmbeddings
          : faceEmbeddings as List<List<double>>?,
      shiftId: identical(shiftId, _sentinel)
          ? this.shiftId
          : shiftId as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'last_name': lastName,
      'email': email,
      'role': role.metadataValue,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
      'shift_id': shiftId,
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
          lastName == other.lastName &&
          email == other.email &&
          role == other.role &&
          companyId == other.companyId &&
          createdAt == other.createdAt &&
          faceEmbeddings == other.faceEmbeddings &&
          shiftId == other.shiftId;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        lastName,
        email,
        role,
        companyId,
        createdAt,
        faceEmbeddings,
        shiftId,
      );
}

