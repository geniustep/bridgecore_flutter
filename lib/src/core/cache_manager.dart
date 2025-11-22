/// Cache manager for storing API responses
/// 
/// Provides in-memory caching with TTL (Time To Live) support
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  Duration defaultTTL = const Duration(minutes: 5);

  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if expired
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// Set cached value
  void set<T>(String key, T value, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? defaultTTL);
    _cache[key] = _CacheEntry(value: value, expiresAt: expiresAt);
  }

  /// Remove cached value
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiresAt.isBefore(now));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    clearExpired();
    return {
      'total_entries': _cache.length,
      'keys': _cache.keys.toList(),
    };
  }

  /// Check if key exists and is valid
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _cache.remove(key);
      return false;
    }
    return true;
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });
}

