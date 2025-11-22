import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthService', () {
    setUp(() {
      BridgeCore.initialize(
        baseUrl: 'https://api.example.com',
        debugMode: false,
      );
    });

    test('should check login status', () async {
      // Note: flutter_secure_storage requires platform implementation
      // In unit tests, this would need a mock TokenManager
      // For now, we just verify the method exists and returns a Future<bool>
      final isLoggedInFuture = BridgeCore.instance.auth.isLoggedIn;
      expect(isLoggedInFuture, isA<Future<bool>>());
    }, skip: 'Requires platform implementation for flutter_secure_storage');

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

