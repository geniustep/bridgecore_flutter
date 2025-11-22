import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BridgeCore', () {
    setUp(() {
      // Clear any existing instance
      // Note: In real tests, you'd need to reset the singleton
    });

    test('should throw exception if not initialized', () {
      expect(() => BridgeCore.instance, throwsException);
    });

    test('should initialize successfully', () {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
        debugMode: false,
      );

      expect(BridgeCore.instance, isNotNull);
      expect(BridgeCore.instance.auth, isNotNull);
      expect(BridgeCore.instance.odoo, isNotNull);
    });

    test('should enable cache', () {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
        enableCache: true,
      );

      BridgeCore.instance.setCacheEnabled(true);
      expect(BridgeCore.instance.getCacheStats(), isNotNull);
    });

    test('should get metrics', () {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
      );

      final metrics = BridgeCore.instance.getMetrics();
      expect(metrics, isA<Map<String, dynamic>>());
      expect(metrics['total_requests'], isNotNull);
    });
  });
}

