import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  group('Exceptions', () {
    test('BridgeCoreException should contain all details', () {
      final exception = BridgeCoreException(
        'Test error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'POST',
        details: {'field': 'value'},
      );

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(400));
      expect(exception.endpoint, equals('/api/test'));
      expect(exception.method, equals('POST'));
      expect(exception.details, isNotNull);
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('Status: 400'));
    });

    test('UnauthorizedException should be created correctly', () {
      final exception = UnauthorizedException(
        'Unauthorized',
        statusCode: 401,
      );

      expect(exception, isA<BridgeCoreException>());
      expect(exception.statusCode, equals(401));
    });

    test('TenantSuspendedException should be created correctly', () {
      final exception = TenantSuspendedException(
        'Tenant suspended',
        statusCode: 403,
      );

      expect(exception, isA<ForbiddenException>());
      expect(exception.statusCode, equals(403));
    });

    test('NetworkException should have status code 0', () {
      final exception = NetworkException('Network error');
      expect(exception.statusCode, equals(0));
    });

    test('Exception should convert to map', () {
      final exception = BridgeCoreException(
        'Test error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
      );

      final map = exception.toMap();
      expect(map['message'], equals('Test error'));
      expect(map['status_code'], equals(500));
      expect(map['endpoint'], equals('/api/test'));
      expect(map['method'], equals('GET'));
      expect(map['timestamp'], isNotNull);
    });
  });
}

