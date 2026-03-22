class Workstation {
  final String id;
  final String name;
  final String companyId;
  final String? deviceId;

  const Workstation({
    required this.id,
    required this.name,
    required this.companyId,
    this.deviceId,
  });

  Workstation copyWith({
    String? id,
    String? name,
    String? companyId,
    String? deviceId,
  }) {
    return Workstation(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'device_id': deviceId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workstation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          companyId == other.companyId &&
          deviceId == other.deviceId;

  @override
  int get hashCode => Object.hash(id, name, companyId, deviceId);
}
