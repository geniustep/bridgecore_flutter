import 'package:flutter_test/flutter_test.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cache;

    setUp(() {
      cache = CacheManager();
      cache.clear();
    });

    test('should store and retrieve value', () {
      cache.set('key1', 'value1');
      expect(cache.get<String>('key1'), equals('value1'));
    });

    test('should return null for non-existent key', () {
      expect(cache.get('non_existent'), isNull);
    });

    test('should remove value', () {
      cache.set('key1', 'value1');
      cache.remove('key1');
      expect(cache.get('key1'), isNull);
    });

    test('should clear all cache', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      cache.clear();
      expect(cache.get('key1'), isNull);
      expect(cache.get('key2'), isNull);
    });

    test('should check if key exists', () {
      cache.set('key1', 'value1');
      expect(cache.has('key1'), isTrue);
      expect(cache.has('key2'), isFalse);
    });

    test('should expire entries after TTL', () async {
      cache.set('key1', 'value1', ttl: const Duration(milliseconds: 100));
      expect(cache.get('key1'), equals('value1'));
      
      await Future.delayed(const Duration(milliseconds: 150));
      expect(cache.get('key1'), isNull);
    });

    test('should get cache statistics', () {
      cache.set('key1', 'value1');
      cache.set('key2', 'value2');
      
      final stats = cache.getStats();
      expect(stats['total_entries'], equals(2));
      expect(stats['keys'], isA<List>());
    });
  });
}

