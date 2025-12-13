/// Trip update model from webhook events
class TripUpdate {
  final int tripId;
  final String? reference;
  final String? name;
  final String state;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? vehicleName;
  final String? vehiclePlate;
  final double? latitude;
  final double? longitude;
  final DateTime? lastGpsUpdate;
  final String event; // 'create', 'write', 'unlink'
  final DateTime timestamp;

  TripUpdate({
    required this.tripId,
    this.reference,
    this.name,
    required this.state,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleName,
    this.vehiclePlate,
    this.latitude,
    this.longitude,
    this.lastGpsUpdate,
    required this.event,
    required this.timestamp,
  });

  /// Check if trip is ongoing (driver should send GPS automatically)
  bool get isOngoing => state == 'ongoing';

  /// Check if trip is completed
  bool get isCompleted => state == 'done';

  /// Check if trip is cancelled
  bool get isCancelled => state == 'cancelled';

  factory TripUpdate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return TripUpdate(
      tripId: json['record_id'] as int? ?? data['id'] as int? ?? 0,
      reference: data['reference'] as String?,
      name: data['name'] as String?,
      state: data['state'] as String? ?? 'draft',
      driverId: data['driver_id'] is List
          ? (data['driver_id'] as List).first as int
          : data['driver_id'] as int?,
      driverName: data['driver_id'] is List
          ? (data['driver_id'] as List).last as String
          : data['driver_name'] as String?,
      vehicleId: data['vehicle_id'] is List
          ? (data['vehicle_id'] as List).first as int
          : data['vehicle_id'] as int?,
      vehicleName: data['vehicle_id'] is List
          ? (data['vehicle_id'] as List).last as String
          : data['vehicle_name'] as String?,
      vehiclePlate: data['vehicle_plate'] as String?,
      latitude: data['current_latitude'] != null
          ? (data['current_latitude'] as num).toDouble()
          : null,
      longitude: data['current_longitude'] != null
          ? (data['current_longitude'] as num).toDouble()
          : null,
      lastGpsUpdate: data['last_gps_update'] != null
          ? DateTime.parse(data['last_gps_update'] as String)
          : null,
      event: json['event'] as String? ?? 'write',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_id': tripId,
      if (reference != null) 'reference': reference,
      if (name != null) 'name': name,
      'state': state,
      if (driverId != null) 'driver_id': driverId,
      if (driverName != null) 'driver_name': driverName,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (vehicleName != null) 'vehicle_name': vehicleName,
      if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (lastGpsUpdate != null)
        'last_gps_update': lastGpsUpdate!.toIso8601String(),
      'event': event,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TripUpdate(tripId: $tripId, state: $state, event: $event)';
  }
}
