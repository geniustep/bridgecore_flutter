/// Driver location model for live tracking
class DriverLocation {
  final int driverId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;
  final String? requestId;

  DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    this.requestId,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      driverId: json['driver_id'] as int,
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
      requestId: json['request_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      if (requestId != null) 'request_id': requestId,
    };
  }

  @override
  String toString() {
    return 'DriverLocation(driverId: $driverId, lat: $latitude, lng: $longitude, speed: $speed)';
  }
}
