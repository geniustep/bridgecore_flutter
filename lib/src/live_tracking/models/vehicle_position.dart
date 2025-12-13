/// Vehicle position model from webhook events
class VehiclePosition {
  final int id;
  final int vehicleId;
  final int? driverId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;
  final String? note;

  VehiclePosition({
    required this.id,
    required this.vehicleId,
    this.driverId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    this.note,
  });

  factory VehiclePosition.fromJson(Map<String, dynamic> json) {
    return VehiclePosition(
      id: json['id'] as int? ?? 0,
      vehicleId: json['vehicle_id'] is List
          ? (json['vehicle_id'] as List).first as int
          : json['vehicle_id'] as int,
      driverId: json['driver_id'] is List
          ? (json['driver_id'] as List).first as int
          : json['driver_id'] as int?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading:
          json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      if (driverId != null) 'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      if (note != null) 'note': note,
    };
  }

  @override
  String toString() {
    return 'VehiclePosition(id: $id, vehicleId: $vehicleId, lat: $latitude, lng: $longitude)';
  }
}
