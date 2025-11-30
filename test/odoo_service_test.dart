import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter/src/client/http_client.dart';

void main() {
  group('OdooService', () {
    setUp(() {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
        debugMode: false,
      );
    });

    test('should have odoo service instance', () {
      expect(BridgeCore.instance.odoo, isNotNull);
    });

    test('searchRead works without fields and reads "records" key', () async {
      final fakeClient = _FakeHttpClient();
      fakeClient.nextResponse = {
        'success': true,
        'records': [
          {'id': 1, 'name': 'Trip 1'},
        ],
      };

      final service = OdooService(httpClient: fakeClient);

      final records = await service.searchRead(
        model: 'shuttle.trip',
      );

      expect(records, isA<List<Map<String, dynamic>>>());
      expect(records.length, equals(1));
      expect(records.first['name'], equals('Trip 1'));
    });

    // Note: These tests require a real API endpoint and authentication
    // In a real scenario, you'd use a mock HTTP client
    /*
    test('should search read records', () async {
      final records = await BridgeCore.instance.odoo.searchRead(
        model: 'res.partner',
        domain: [],
        fields: ['name', 'email'],
        limit: 10,
      );
      
      expect(records, isA<List<Map<String, dynamic>>>());
    });

    test('should create record', () async {
      final id = await BridgeCore.instance.odoo.create(
        model: 'res.partner',
        values: {
          'name': 'Test Company',
          'email': 'test@example.com',
        },
      );
      
      expect(id, isA<int>());
      expect(id, greaterThan(0));
    });

    test('should batch create records', () async {
      final ids = await BridgeCore.instance.odoo.batchCreate(
        model: 'res.partner',
        valuesList: [
          {'name': 'Company 1'},
          {'name': 'Company 2'},
        ],
      );
      
      expect(ids, isA<List<int>>());
      expect(ids.length, equals(2));
    });
    */
  });
}

/// No-op token manager to avoid secure storage in tests
class _DummyTokenManager extends TokenManager {
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    int? refreshExpiresIn,
  }) async {}

  @override
  Future<String?> getAccessToken() async => 'token';

  @override
  Future<String?> getRefreshToken() async => 'refresh';

  @override
  Future<String?> getValidAccessToken() async => 'token';

  @override
  Future<bool> hasTokens() async => true;

  @override
  Future<void> clearTokens() async {}
}

/// Fake HTTP client that returns preset responses
class _FakeHttpClient extends BridgeCoreHttpClient {
  _FakeHttpClient()
      : super(
          baseUrl: 'https://example.com',
          tokenManager: _DummyTokenManager(),
          enableRetry: false,
        );

  Map<String, dynamic>? nextResponse;

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    return nextResponse ?? {'records': []};
  }
}

