import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

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

