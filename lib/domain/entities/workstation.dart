class WorkstationRoi {
  final double x;
  final double y;
  final double width;
  final double height;

  const WorkstationRoi({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory WorkstationRoi.fromMap(Map<String, dynamic> map) {
    return WorkstationRoi(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkstationRoi &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

class Workstation {
  final String id;
  final String name;
  final String companyId;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final double? geofenceRadius;
  final String? assignedEmployeeId;
  final String status;
  final WorkstationRoi? roi;

  const Workstation({
    required this.id,
    required this.name,
    required this.companyId,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.geofenceRadius,
    this.assignedEmployeeId,
    this.status = 'IDLE',
    this.roi,
  });

  Workstation copyWith({
    String? id,
    String? name,
    String? companyId,
    String? deviceId,
    double? latitude,
    double? longitude,
    double? geofenceRadius,
    String? assignedEmployeeId,
    String? status,
    WorkstationRoi? roi,
  }) {
    return Workstation(
      id: id ?? this.id,
      name: name ?? this.name,
      companyId: companyId ?? this.companyId,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      status: status ?? this.status,
      roi: roi ?? this.roi,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company_id': companyId,
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius': geofenceRadius,
      'assigned_employee_id': assignedEmployeeId,
      'status': status,
      'roi': roi?.toMap(),
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
          deviceId == other.deviceId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          geofenceRadius == other.geofenceRadius &&
          assignedEmployeeId == other.assignedEmployeeId &&
          status == other.status &&
          roi == other.roi;

  @override
  int get hashCode => Object.hash(
      id, name, companyId, deviceId, latitude, longitude, geofenceRadius, assignedEmployeeId, status, roi);
}
