# 📍 دليل التتبع الحي - Live Tracking Guide

## نظرة عامة

هذا الدليل يشرح كيفية استخدام خدمة التتبع الحي (Live Tracking) في `bridgecore_flutter` للتكامل مع ShuttleBee.

## المميزات

- ✅ اتصال WebSocket مع BridgeCore
- ✅ تتبع حي للمركبات (عندما الرحلة `ongoing`)
- ✅ طلب موقع السائق عند الحاجة (عندما الرحلة غير `ongoing`)
- ✅ إعادة الاتصال التلقائي
- ✅ Streams للتحديثات الفورية

---

## التثبيت

```yaml
dependencies:
  bridgecore_flutter: ^3.1.0
```

---

## الإعداد

```dart
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  BridgeCore.initialize(
    baseUrl: 'https://your-bridgecore-url.com',
    enableLogging: true,
  );
  
  runApp(MyApp());
}
```

---

## استخدام للـ Dispatcher (لوحة التحكم)

### الاتصال والاشتراك

```dart
class DispatcherDashboard extends StatefulWidget {
  @override
  _DispatcherDashboardState createState() => _DispatcherDashboardState();
}

class _DispatcherDashboardState extends State<DispatcherDashboard> {
  late final LiveTrackingService _tracking;
  
  @override
  void initState() {
    super.initState();
    _initTracking();
  }
  
  Future<void> _initTracking() async {
    _tracking = BridgeCore.instance.liveTracking;
    
    // الاتصال بـ WebSocket
    await _tracking.connect(userId: currentUserId);
    
    // الاشتراك في التتبع الحي
    await _tracking.subscribeLiveTracking();
    
    // الاستماع لتحديثات المواقع (من الرحلات الجارية)
    _tracking.vehiclePositionStream.listen(_onVehiclePositionUpdate);
    
    // الاستماع لتحديثات الرحلات
    _tracking.tripUpdateStream.listen(_onTripUpdate);
    
    // الاستماع لردود طلبات الموقع
    _tracking.locationResponseStream.listen(_onLocationResponse);
    
    // الاستماع لحالة الاتصال
    _tracking.connectionStatusStream.listen((isConnected) {
      print('WebSocket connected: $isConnected');
    });
  }
  
  void _onVehiclePositionUpdate(VehiclePosition position) {
    // تحديث موقع المركبة على الخريطة
    setState(() {
      markers[position.vehicleId] = Marker(
        position: LatLng(position.latitude, position.longitude),
        rotation: position.heading ?? 0,
      );
    });
  }
  
  void _onTripUpdate(TripUpdate tripUpdate) {
    print('Trip ${tripUpdate.tripId} state: ${tripUpdate.state}');
    
    if (tripUpdate.isOngoing) {
      // الرحلة بدأت - ستأتي تحديثات GPS تلقائياً
    } else if (tripUpdate.isCompleted) {
      // الرحلة انتهت
    }
  }
  
  void _onLocationResponse(DriverLocation location) {
    // استلام موقع من سائق (عند الطلب)
    print('Driver ${location.driverId} is at ${location.latitude}, ${location.longitude}');
  }
  
  // طلب موقع سائق (عندما الرحلة غير ongoing)
  Future<void> requestDriverLocation(int driverId) async {
    final location = await _tracking.requestDriverLocation(driverId: driverId);
    
    if (location != null) {
      // تحديث الخريطة
      updateMapMarker(driverId, location.latitude, location.longitude);
    } else {
      // السائق غير متصل أو انتهت مهلة الطلب
      showSnackBar('Could not get driver location');
    }
  }
  
  @override
  void dispose() {
    _tracking.disconnect();
    super.dispose();
  }
}
```

---

## استخدام للـ Driver (تطبيق السائق)

### الإعداد الأساسي

```dart
class DriverTrackingService {
  late final LiveTrackingService _tracking;
  Timer? _autoTrackingTimer;
  bool _isAutoTracking = false;
  int? _currentTripId;
  int? _currentVehicleId;
  
  Future<void> init(int driverId) async {
    _tracking = BridgeCore.instance.liveTracking;
    
    // الاتصال بـ WebSocket
    await _tracking.connect(userId: driverId);
    
    // الاستماع لطلبات الموقع من الـ Dispatcher
    _tracking.locationRequestStream.listen(_onLocationRequest);
    
    // الاستماع لتحديثات حالة الرحلة
    _tracking.tripUpdateStream.listen(_onTripUpdate);
    
    // تحديث حالة السائق
    _tracking.updateDriverStatus(status: DriverStatus.online);
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // التعامل مع طلبات الموقع (عندما الرحلة غير ongoing)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _onLocationRequest(LocationRequest request) async {
    // الـ Dispatcher يطلب الموقع الحالي
    final position = await _getCurrentGpsPosition();
    
    _tracking.sendLocationResponse(
      requestId: request.requestId,
      requesterId: request.requesterId,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
    );
    
    print('📍 Sent location to dispatcher');
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // التعامل مع تحديثات حالة الرحلة
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _onTripUpdate(TripUpdate tripUpdate) {
    if (tripUpdate.isOngoing && !_isAutoTracking) {
      // بدء التتبع التلقائي
      _currentTripId = tripUpdate.tripId;
      _currentVehicleId = tripUpdate.vehicleId;
      _startAutoTracking();
    } else if (!tripUpdate.isOngoing && _isAutoTracking) {
      // إيقاف التتبع التلقائي
      _stopAutoTracking();
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // التتبع التلقائي (عندما الرحلة ongoing)
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _startAutoTracking() {
    if (_isAutoTracking) return;
    
    _isAutoTracking = true;
    print('🟢 Auto tracking started');
    
    // إرسال الموقع فوراً
    _sendGpsToServer();
    
    // إرسال الموقع كل 10 ثواني
    _autoTrackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendGpsToServer(),
    );
  }
  
  void _stopAutoTracking() {
    _autoTrackingTimer?.cancel();
    _autoTrackingTimer = null;
    _isAutoTracking = false;
    print('🔴 Auto tracking stopped');
  }
  
  Future<void> _sendGpsToServer() async {
    if (_currentVehicleId == null) return;
    
    try {
      final position = await _getCurrentGpsPosition();
      
      // إرسال الموقع إلى Odoo عبر BridgeCore
      await BridgeCore.instance.odoo.create(
        model: 'shuttle.vehicle.position',
        values: {
          'vehicle_id': _currentVehicleId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
        },
      );
      
      print('📍 GPS sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Failed to send GPS: $e');
    }
  }
  
  Future<GpsPosition> _getCurrentGpsPosition() async {
    // استخدم geolocator أو location package
    // هذا مثال فقط
    return GpsPosition(
      latitude: 33.5731,
      longitude: -7.5898,
      speed: 45.0,
      heading: 180.0,
      accuracy: 10.0,
    );
  }
  
  void dispose() {
    _stopAutoTracking();
    _tracking.updateDriverStatus(status: DriverStatus.offline);
    _tracking.disconnect();
  }
}

class GpsPosition {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  
  GpsPosition({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
  });
}
```

---

## Models

### VehiclePosition

```dart
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
}
```

### TripUpdate

```dart
class TripUpdate {
  final int tripId;
  final String state;  // 'draft', 'planned', 'ongoing', 'done', 'cancelled'
  final int? driverId;
  final int? vehicleId;
  final double? latitude;
  final double? longitude;
  final String event;  // 'create', 'write', 'unlink'
  
  bool get isOngoing => state == 'ongoing';
  bool get isCompleted => state == 'done';
}
```

### DriverLocation

```dart
class DriverLocation {
  final int driverId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? requestId;
}
```

---

## Event Types

يمكنك الاستماع للأحداث عبر EventBus:

```dart
BridgeCore.instance.events.on(BridgeCoreEventTypes.websocketConnected).listen((event) {
  print('WebSocket connected!');
});

BridgeCore.instance.events.on(BridgeCoreEventTypes.websocketDisconnected).listen((event) {
  print('WebSocket disconnected!');
});

BridgeCore.instance.events.on(BridgeCoreEventTypes.websocketMessage).listen((event) {
  print('Message: ${event.data}');
});
```

---

## التدفق الكامل

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         حالة الرحلة: ongoing                                  │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Driver App                 BridgeCore                  Dispatcher App      │
│   ┌─────────┐    POST       ┌───────────┐  WebSocket   ┌─────────────┐      │
│   │  Auto   │ ────────────▶ │   Odoo    │ ───────────▶ │   Live      │      │
│   │  GPS    │  every 10s    │  Create   │  broadcast   │   Map       │      │
│   └─────────┘               └───────────┘              └─────────────┘      │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│                      حالة الرحلة: draft / confirmed                          │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Dispatcher App             BridgeCore                  Driver App          │
│   ┌─────────┐  request_      ┌───────────┐  WebSocket   ┌─────────────┐     │
│   │  Where  │  driver_       │   Relay   │ ───────────▶ │  Get GPS    │     │
│   │  is he? │  location      │           │              │  & Respond  │     │
│   └─────────┘ ──────────────▶└───────────┘◀──────────── └─────────────┘     │
│        ▲                           │        location                         │
│        │                           │        response                         │
│        └───────────────────────────┘                                         │
│                 location_response                                            │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## إعداد Odoo

لا تنسى إضافة Webhook Configurations في Odoo:

1. **shuttle.vehicle.position** - Create Only, High Priority, Instant Send
2. **shuttle.trip** - Create & Write, High Priority, Instant Send

---

## الأسئلة الشائعة

### لماذا لا تصل تحديثات GPS؟

1. تأكد من أن Webhook Configuration مُفعّل في Odoo
2. تأكد من أن `instant_send = True`
3. تأكد من الاشتراك في `subscribeLiveTracking()`

### كيف أختبر بدون سائق حقيقي؟

يمكنك إنشاء سجل `shuttle.vehicle.position` من Odoo مباشرة أو عبر API.

### ما الفرق بين vehiclePositionStream و locationResponseStream؟

- `vehiclePositionStream`: تحديثات تلقائية من رحلات ongoing (محفوظة في DB)
- `locationResponseStream`: ردود على طلبات الموقع (غير محفوظة في DB)

---

**آخر تحديث**: ديسمبر 2024
