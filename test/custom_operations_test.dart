import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';
import 'package:bridgecore_flutter/src/client/http_client.dart';

void main() {
  group('CustomOperations - Odoo 18', () {
    late CustomOperations customOps;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      customOps = CustomOperations(mockClient);
      OdooContext.clear(); // Clear context before each test
    });

    tearDown(() {
      OdooContext.clear();
    });

    group('callMethod', () {
      test('should call method with context', () async {
        // Arrange
        final expectedContext = {'lang': 'ar_001', 'tz': 'Asia/Riyadh'};
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.callMethod(
          model: 'sale.order',
          method: 'action_confirm',
          ids: [1],
          context: expectedContext,
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['context'], expectedContext);
      });

      test('should merge default context with provided context', () async {
        // Arrange
        OdooContext.setDefault(lang: 'en_US', timezone: 'UTC');
        mockClient.mockResponse = {'result': true};

        // Act
        await customOps.callMethod(
          model: 'sale.order',
          method: 'action_confirm',
          ids: [1],
          context: {'lang': 'ar_001'}, // Override lang
        );

        // Assert
        final requestContext = mockClient.lastRequest?['context'];
        expect(requestContext['lang'], 'ar_001'); // Overridden
        expect(requestContext['tz'], 'UTC'); // From default
      });

      test('should handle action result', () async {
        // Arrange
        mockClient.mockResponse = {
          'result': {
            'type': 'ir.actions.act_window',
            'res_model': 'sale.order',
            'view_mode': 'form',
            'res_id': 123,
          }
        };

        // Act
        final result = await customOps.callMethod(
          model: 'sale.order',
          method: 'action_view_order',
          ids: [1],
        );

        // Assert
        expect(result.success, true);
        expect(result.isAction, true);
        expect(result.action?['type'], 'ir.actions.act_window');
        expect(result.action?['res_model'], 'sale.order');
      });

      test('should handle error with details', () async {
        // Arrange
        mockClient.mockResponse = {
          'error': {
            'message': 'Validation Error',
            'code': 'validation_error',
            'data': {
              'field': 'partner_id',
              'value': null,
            }
          }
        };

        // Act
        final result = await customOps.callMethod(
          model: 'sale.order',
          method: 'action_confirm',
          ids: [1],
        );

        // Assert
        expect(result.success, false);
        expect(result.error, 'Validation Error');
        expect(result.errorDetails?['code'], 'validation_error');
        expect(result.errorDetails?['data']?['field'], 'partner_id');
      });

      test('should handle warnings', () async {
        // Arrange
        mockClient.mockResponse = {
          'result': true,
          'warnings': [
            {'message': 'Stock is low', 'type': 'warning'}
          ]
        };

        // Act
        final result = await customOps.callMethod(
          model: 'sale.order',
          method: 'action_confirm',
          ids: [1],
        );

        // Assert
        expect(result.success, true);
        expect(result.hasWarnings, true);
        expect(result.warnings?.length, 1);
      });
    });

    group('callKw', () {
      test('should call with args and kwargs', () async {
        // Arrange
        mockClient.mockResponse = {
          'result': [
            {'id': 1, 'name': 'Partner 1'},
            {'id': 2, 'name': 'Partner 2'},
          ]
        };

        // Act
        final result = await customOps.callKw(
          model: 'res.partner',
          method: 'search_read',
          args: [
            [
              ['is_company', '=', true]
            ]
          ],
          kwargs: {
            'fields': ['name', 'email'],
            'limit': 10,
          },
          context: {'lang': 'ar_001'},
        );

        // Assert
        expect(result.success, true);
        expect(result.result, isList);
        expect((result.result as List).length, 2);
      });

      test('should merge context into kwargs', () async {
        // Arrange
        mockClient.mockResponse = {'result': []};

        // Act
        await customOps.callKw(
          model: 'res.partner',
          method: 'search',
          args: [[]],
          context: {'lang': 'ar_001', 'tz': 'Asia/Riyadh'},
        );

        // Assert
        final kwargs = mockClient.lastRequest?['kwargs'];
        expect(kwargs['context'], isNotNull);
        expect(kwargs['context']['lang'], 'ar_001');
        expect(kwargs['context']['tz'], 'Asia/Riyadh');
      });
    });

    group('Action Methods', () {
      test('actionConfirm should call action_confirm', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionConfirm(
          model: 'sale.order',
          ids: [1, 2, 3],
          context: {'lang': 'ar_001'},
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_confirm');
        expect(mockClient.lastRequest?['ids'], [1, 2, 3]);
      });

      test('actionValidate should call action_validate', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionValidate(
          model: 'stock.picking',
          ids: [5],
          context: {'lang': 'ar_001'},
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_validate');
      });

      test('actionDone should call action_done by default', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionDone(
          model: 'purchase.order',
          ids: [10],
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_done');
      });

      test('actionDone should accept custom method name', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionDone(
          model: 'mrp.production',
          ids: [15],
          methodName: 'button_mark_done',
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'button_mark_done');
      });

      test('actionApprove should call action_approve', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionApprove(
          model: 'hr.leave',
          ids: [20],
          context: {'lang': 'ar_001'},
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_approve');
      });

      test('actionReject should call action_refuse by default', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionReject(
          model: 'hr.leave',
          ids: [25],
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_refuse');
      });

      test('actionAssign should call action_assign', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionAssign(
          model: 'stock.picking',
          ids: [30],
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_assign');
      });

      test('actionUnlock should call button_draft by default', () async {
        // Arrange
        mockClient.mockResponse = {'result': true};

        // Act
        final result = await customOps.actionUnlock(
          model: 'account.move',
          ids: [35],
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'button_draft');
      });

      test('executeButtonAction should call custom button method', () async {
        // Arrange
        mockClient.mockResponse = {'result': {'type': 'ir.actions.act_window'}};

        // Act
        final result = await customOps.executeButtonAction(
          model: 'sale.order',
          buttonMethod: 'action_quotation_send',
          ids: [40],
          context: {'lang': 'ar_001'},
        );

        // Assert
        expect(result.success, true);
        expect(mockClient.lastRequest?['method'], 'action_quotation_send');
      });
    });

    group('OdooContext', () {
      test('should set and get default context', () {
        // Act
        OdooContext.setDefault(
          lang: 'ar_001',
          timezone: 'Asia/Riyadh',
          allowedCompanyIds: [1, 2],
        );

        // Assert
        final context = OdooContext.defaultContext;
        expect(context?['lang'], 'ar_001');
        expect(context?['tz'], 'Asia/Riyadh');
        expect(context?['allowed_company_ids'], [1, 2]);
      });

      test('should update specific values', () {
        // Arrange
        OdooContext.setDefault(lang: 'en_US', timezone: 'UTC');

        // Act
        OdooContext.update(lang: 'ar_001');

        // Assert
        final context = OdooContext.defaultContext;
        expect(context?['lang'], 'ar_001');
        expect(context?['tz'], 'UTC'); // Should remain unchanged
      });

      test('should clear context', () {
        // Arrange
        OdooContext.setDefault(lang: 'ar_001');

        // Act
        OdooContext.clear();

        // Assert
        expect(OdooContext.defaultContext, isNull);
      });

      test('should merge contexts correctly', () {
        // Arrange
        OdooContext.setDefault(lang: 'en_US', timezone: 'UTC', uid: 1);

        // Act
        final merged = OdooContext.merge({'lang': 'ar_001', 'custom': 'value'});

        // Assert
        expect(merged?['lang'], 'ar_001'); // Overridden
        expect(merged?['tz'], 'UTC'); // From default
        expect(merged?['uid'], 1); // From default
        expect(merged?['custom'], 'value'); // From provided
      });
    });
  });
}

/// Mock HTTP Client for testing
class MockHttpClient extends BridgeCoreHttpClient {
  Map<String, dynamic>? mockResponse;
  Map<String, dynamic>? lastRequest;

  MockHttpClient()
      : super(
          baseUrl: 'https://test.example.com',
          tokenManager: MockTokenManager(),
        );

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    lastRequest = body;
    return mockResponse ?? {'result': true};
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    return mockResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    return mockResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    bool includeAuth = true,
  }) async {
    return mockResponse ?? {};
  }

  @override
  Future<Map<String, dynamic>> upload(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    void Function(int sent, int total)? onProgress,
  }) async {
    return mockResponse ?? {};
  }

  @override
  Future<void> download(
    String path,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {}
}

/// Mock Token Manager for testing
class MockTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => 'mock_access_token';

  @override
  Future<String?> getRefreshToken() async => 'mock_refresh_token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    int? refreshExpiresIn,
  }) async {}

  @override
  Future<String?> getValidAccessToken() async => 'mock_access_token';

  @override
  Future<void> clearTokens() async {}
}
