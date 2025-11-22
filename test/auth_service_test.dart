import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  group('AuthService', () {
    setUp(() {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
        debugMode: false,
      );
    });

    test('should check login status', () async {
      final isLoggedIn = await BridgeCore.instance.auth.isLoggedIn;
      expect(isLoggedIn, isA<bool>());
    });

    // Note: These tests require a real API endpoint
    // In a real scenario, you'd use a mock HTTP client
    /*
    test('should login successfully', () async {
      final session = await BridgeCore.instance.auth.login(
        email: 'test@example.com',
        password: 'password',
      );
      
      expect(session, isNotNull);
      expect(session.accessToken, isNotEmpty);
      expect(session.user.email, equals('test@example.com'));
    });
    */
  });
}

