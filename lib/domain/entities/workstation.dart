class Workstation {
  final String id;
  final String name;
  final String companyId;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final double? geofenceRadius;

  const Workstation({
    required this.id,
    required this.name,
    required this.companyId,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.geofenceRadius,
  });

  Workstation copyWith({
    String? id,
    String? name,
    String? companyId,
    String? deviceId,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
  }) {
    return Workstation(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workstation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          companyId == other.companyId &&
          deviceId == other.deviceId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          geofenceRadius == other.geofenceRadius;

  @override
  int get hashCode => Object.hash(id, name, companyId, deviceId, latitude, longitude, geofenceRadius);
}
