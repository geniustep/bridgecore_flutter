/// Response model for Odoo fields check result
///
/// Contains information about field validation and fetched data from Odoo
class OdooFieldsData {
  /// Whether the check was successful
  final bool success;

  /// Whether the model exists in Odoo
  final bool modelExists;

  /// Human-readable model name
  final String? modelName;

  /// Whether all requested fields exist
  final bool fieldsExist;

  /// Detailed information about each field
  final Map<String, FieldInfo>? fieldsInfo;

  /// Actual data fetched from Odoo
  final Map<String, dynamic>? data;

  /// Error message if check failed
  final String? error;

  OdooFieldsData({
    required this.success,
    required this.modelExists,
    this.modelName,
    required this.fieldsExist,
    this.fieldsInfo,
    this.data,
    this.error,
  });

  /// Create from JSON response
  factory OdooFieldsData.fromJson(Map<String, dynamic> json) {
    Map<String, FieldInfo>? fieldsInfo;
    if (json['fields_info'] != null) {
      final fieldsInfoJson = json['fields_info'] as Map<String, dynamic>;
      fieldsInfo = fieldsInfoJson.map(
        (key, value) => MapEntry(
          key,
          FieldInfo.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    return OdooFieldsData(
      success: json['success'] as bool? ?? false,
      modelExists: json['model_exists'] as bool? ?? false,
      modelName: json['model_name'] as String?,
      fieldsExist: json['fields_exist'] as bool? ?? false,
      fieldsInfo: fieldsInfo,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'model_exists': modelExists,
      if (modelName != null) 'model_name': modelName,
      'fields_exist': fieldsExist,
      if (fieldsInfo != null)
        'fields_info': fieldsInfo!.map((key, value) => MapEntry(key, value.toJson())),
      if (data != null) 'data': data,
      if (error != null) 'error': error,
    };
  }

  @override
  String toString() {
    return 'OdooFieldsData(success: $success, modelExists: $modelExists, '
        'fieldsExist: $fieldsExist, error: $error)';
  }
}

/// Information about a single Odoo field
class FieldInfo {
  /// Field ID in Odoo
  final int id;

  /// Technical field name
  final String name;

  /// Human-readable field description
  final String fieldDescription;

  /// Field type (char, integer, many2one, etc.)
  final String ttype;

  FieldInfo({
    required this.id,
    required this.name,
    required this.fieldDescription,
    required this.ttype,
  });

  /// Create from JSON
  factory FieldInfo.fromJson(Map<String, dynamic> json) {
    return FieldInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      fieldDescription: json['field_description'] as String,
      ttype: json['ttype'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'field_description': fieldDescription,
      'ttype': ttype,
    };
  }

  @override
  String toString() {
    return 'FieldInfo(name: $name, type: $ttype, description: $fieldDescription)';
  }
}

