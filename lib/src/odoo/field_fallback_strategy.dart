import 'dart:async';
import '../core/logger.dart';

/// Strategy for handling invalid fields in Odoo operations
///
/// When an Odoo operation fails due to invalid fields, this strategy
/// automatically retries with a reduced set of fields.
///
/// Strategy levels:
/// 1. Original fields (user-provided)
/// 2. Without invalid fields (remove problematic fields)
/// 3. Basic fields only (id, name, display_name)
/// 4. Minimal fields (id only)
class FieldFallbackStrategy {
  final String model;
  final Future<Map<String, dynamic>> Function(String model)? onFieldsGet;

  List<String> _originalFields = [];
  List<String> _currentFields = [];
  final Set<String> _invalidFields = {};
  int _retryCount = 0;
  int _currentLevel = 1;

  // Global cache of invalid fields per model
  static final Map<String, Set<String>> _globalInvalidFieldsCache = {};

  FieldFallbackStrategy({
    required this.model,
    this.onFieldsGet,
  });

  // ════════════════════════════════════════════════════════════
  // Initialization
  // ════════════════════════════════════════════════════════════

  /// Initialize with fields
  void initialize(List<String> fields) {
    _originalFields = List.from(fields);
    _currentFields = List.from(fields);
    _retryCount = 0;
    _currentLevel = 1;

    // Apply globally cached invalid fields
    if (_globalInvalidFieldsCache.containsKey(model)) {
      _invalidFields.addAll(_globalInvalidFieldsCache[model]!);
      _currentFields.removeWhere((f) => _invalidFields.contains(f));
    }
  }

  // ════════════════════════════════════════════════════════════
  // Handle Invalid Field Error
  // ════════════════════════════════════════════════════════════

  /// Handle invalid field error and return new fields to try
  ///
  /// Returns null if strategy is exhausted
  Future<List<String>?> handleInvalidField(String errorMessage) async {
    _retryCount++;

    // Extract field name from error message
    final fieldName = _extractFieldNameFromError(errorMessage);

    if (fieldName != null && fieldName.isNotEmpty) {
      BridgeCoreLogger.debug('Invalid field detected: $fieldName');

      // Add to invalid fields cache
      _invalidFields.add(fieldName);
      _cacheInvalidField(model, fieldName);

      // Remove from current fields
      _currentFields.remove(fieldName);

      if (_currentFields.isNotEmpty) {
        BridgeCoreLogger.debug('Retry with ${_currentFields.length} fields');
        return _currentFields;
      }
    }

    // Move to next level
    return await _moveToNextLevel();
  }

  /// Extract field name from error message
  String? _extractFieldNameFromError(String error) {
    // Pattern: "Invalid field 'field_name' on model 'model.name'"
    final regex = RegExp("Invalid field ['\"]([^'\"]+)['\"]");
    final match = regex.firstMatch(error);

    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  // ════════════════════════════════════════════════════════════
  // Fallback Levels
  // ════════════════════════════════════════════════════════════

  /// Move to next fallback level
  Future<List<String>?> _moveToNextLevel() async {
    _currentLevel++;

    switch (_currentLevel) {
      case 2:
        // Level 2: Try basic fields
        return _getBasicFields();

      case 3:
        // Level 3: Try minimal fields
        return _getMinimalFields();

      case 4:
        // Level 4: Fetch fields from server
        if (onFieldsGet != null) {
          return await _getValidFieldsFromServer();
        }
        return null;

      default:
        // Strategy exhausted
        throw Exception(
          'Field fallback strategy exhausted for model $model. '
          'Invalid fields: ${_invalidFields.join(", ")}',
        );
    }
  }

  /// Get basic fields
  List<String> _getBasicFields() {
    final basic = ['id', 'name', 'display_name', 'create_date', 'write_date'];
    _currentFields = basic.where((f) => !_invalidFields.contains(f)).toList();

    BridgeCoreLogger.debug('Level 2: Basic fields (${_currentFields.length})');
    return _currentFields;
  }

  /// Get minimal fields
  List<String> _getMinimalFields() {
    final minimal = ['id', 'name', 'display_name'];
    _currentFields = minimal.where((f) => !_invalidFields.contains(f)).toList();

    BridgeCoreLogger.debug('Level 3: Minimal fields (${_currentFields.length})');
    return _currentFields;
  }

  /// Get valid fields from server
  Future<List<String>> _getValidFieldsFromServer() async {
    BridgeCoreLogger.debug('Level 4: Fetching fields from server...');

    try {
      final fieldsInfo = await onFieldsGet!(model);

      // Get all field names
      final allFields = fieldsInfo.keys.toList();

      // Remove known invalid fields
      _currentFields =
          allFields.where((f) => !_invalidFields.contains(f)).toList();

      BridgeCoreLogger.debug('Server fields: ${_currentFields.length}');
      return _currentFields;
    } catch (e) {
      BridgeCoreLogger.error('Failed to fetch fields from server', null, e);
      throw Exception('Unable to fetch valid fields from server');
    }
  }

  // ════════════════════════════════════════════════════════════
  // Getters
  // ════════════════════════════════════════════════════════════

  /// Get current fields
  List<String> getCurrentFields() => List.from(_currentFields);

  /// Get status
  Map<String, dynamic> getStatus() {
    return {
      'model': model,
      'current_level': _currentLevel,
      'retry_count': _retryCount,
      'original_fields_count': _originalFields.length,
      'current_fields_count': _currentFields.length,
      'invalid_fields_count': _invalidFields.length,
      'invalid_fields': _invalidFields.toList(),
      'cached_invalid_fields': _globalInvalidFieldsCache[model]?.toList() ?? [],
    };
  }

  // ════════════════════════════════════════════════════════════
  // Global Cache Management
  // ════════════════════════════════════════════════════════════

  /// Cache invalid field globally
  static void _cacheInvalidField(String model, String fieldName) {
    if (!_globalInvalidFieldsCache.containsKey(model)) {
      _globalInvalidFieldsCache[model] = {};
    }
    _globalInvalidFieldsCache[model]!.add(fieldName);
  }

  /// Get global invalid fields cache
  static Map<String, List<String>> getGlobalInvalidFieldsCache() {
    return _globalInvalidFieldsCache.map(
      (model, fields) => MapEntry(model, fields.toList()),
    );
  }

  /// Clear global cache
  static void clearGlobalCache() {
    _globalInvalidFieldsCache.clear();
    BridgeCoreLogger.debug('Global cache cleared');
  }

  /// Clear cache for specific model
  static void clearModelCache(String model) {
    _globalInvalidFieldsCache.remove(model);
    BridgeCoreLogger.debug('Cache cleared for model: $model');
  }
}
