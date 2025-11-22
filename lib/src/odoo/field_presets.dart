/// Field presets for common Odoo models
/// 
/// Provides predefined field lists for common use cases
enum FieldPreset {
  /// Minimal fields (id, name, display_name)
  minimal,

  /// Basic fields (includes common fields)
  basic,

  /// Standard fields (most commonly used fields)
  standard,

  /// Extended fields (more detailed information)
  extended,

  /// All fields (fetch everything)
  all,
}

/// Manager for field presets
class FieldPresetsManager {
  FieldPresetsManager._();

  // ════════════════════════════════════════════════════════════
  // Common Fields
  // ════════════════════════════════════════════════════════════

  static const List<String> _minimalFields = [
    'id',
    'name',
    'display_name',
  ];

  static const List<String> _basicFields = [
    'id',
    'name',
    'display_name',
    'create_date',
    'write_date',
  ];

  static const List<String> _standardFields = [
    'id',
    'name',
    'display_name',
    'create_uid',
    'create_date',
    'write_uid',
    'write_date',
  ];

  // ════════════════════════════════════════════════════════════
  // Model-Specific Presets
  // ════════════════════════════════════════════════════════════

  /// Partner (res.partner) presets
  static const Map<FieldPreset, List<String>> _partnerPresets = {
    FieldPreset.minimal: [
      'id',
      'name',
      'display_name',
    ],
    FieldPreset.basic: [
      'id',
      'name',
      'display_name',
      'email',
      'phone',
      'mobile',
    ],
    FieldPreset.standard: [
      'id',
      'name',
      'display_name',
      'email',
      'phone',
      'mobile',
      'street',
      'city',
      'country_id',
      'is_company',
      'parent_id',
    ],
    FieldPreset.extended: [
      'id',
      'name',
      'display_name',
      'email',
      'phone',
      'mobile',
      'street',
      'street2',
      'city',
      'state_id',
      'zip',
      'country_id',
      'is_company',
      'parent_id',
      'website',
      'vat',
      'comment',
      'create_date',
      'write_date',
    ],
  };

  /// Product (product.product) presets
  static const Map<FieldPreset, List<String>> _productPresets = {
    FieldPreset.minimal: [
      'id',
      'name',
      'display_name',
    ],
    FieldPreset.basic: [
      'id',
      'name',
      'display_name',
      'default_code',
      'list_price',
      'standard_price',
    ],
    FieldPreset.standard: [
      'id',
      'name',
      'display_name',
      'default_code',
      'barcode',
      'list_price',
      'standard_price',
      'type',
      'categ_id',
      'uom_id',
      'qty_available',
    ],
    FieldPreset.extended: [
      'id',
      'name',
      'display_name',
      'default_code',
      'barcode',
      'list_price',
      'standard_price',
      'type',
      'categ_id',
      'uom_id',
      'uom_po_id',
      'qty_available',
      'virtual_available',
      'description',
      'description_sale',
      'weight',
      'volume',
      'active',
      'create_date',
      'write_date',
    ],
  };

  /// Sale Order (sale.order) presets
  static const Map<FieldPreset, List<String>> _saleOrderPresets = {
    FieldPreset.minimal: [
      'id',
      'name',
      'display_name',
    ],
    FieldPreset.basic: [
      'id',
      'name',
      'display_name',
      'partner_id',
      'date_order',
      'amount_total',
      'state',
    ],
    FieldPreset.standard: [
      'id',
      'name',
      'display_name',
      'partner_id',
      'date_order',
      'validity_date',
      'amount_untaxed',
      'amount_tax',
      'amount_total',
      'state',
      'user_id',
      'company_id',
    ],
    FieldPreset.extended: [
      'id',
      'name',
      'display_name',
      'partner_id',
      'partner_invoice_id',
      'partner_shipping_id',
      'date_order',
      'validity_date',
      'amount_untaxed',
      'amount_tax',
      'amount_total',
      'state',
      'user_id',
      'team_id',
      'company_id',
      'payment_term_id',
      'pricelist_id',
      'note',
      'create_date',
      'write_date',
    ],
  };

  // ════════════════════════════════════════════════════════════
  // Get Fields
  // ════════════════════════════════════════════════════════════

  /// Get fields for a model and preset
  /// 
  /// Returns null if preset is 'all' (fetch all fields from server)
  static List<String>? getFields(String model, FieldPreset preset) {
    // 'all' preset means fetch everything from server
    if (preset == FieldPreset.all) {
      return null;
    }

    // Get model-specific presets
    Map<FieldPreset, List<String>>? modelPresets;

    if (model == 'res.partner') {
      modelPresets = _partnerPresets;
    } else if (model == 'product.product' || model == 'product.template') {
      modelPresets = _productPresets;
    } else if (model == 'sale.order') {
      modelPresets = _saleOrderPresets;
    }

    // Use model-specific preset if available
    if (modelPresets != null && modelPresets.containsKey(preset)) {
      return List.from(modelPresets[preset]!);
    }

    // Fallback to generic presets
    switch (preset) {
      case FieldPreset.minimal:
        return List.from(_minimalFields);
      case FieldPreset.basic:
        return List.from(_basicFields);
      case FieldPreset.standard:
        return List.from(_standardFields);
      case FieldPreset.extended:
        return List.from(_standardFields);
      case FieldPreset.all:
        return null;
    }
  }

  /// Add custom preset for a model
  static final Map<String, Map<FieldPreset, List<String>>> _customPresets = {};

  static void addCustomPreset(
    String model,
    FieldPreset preset,
    List<String> fields,
  ) {
    if (!_customPresets.containsKey(model)) {
      _customPresets[model] = {};
    }
    _customPresets[model]![preset] = fields;
  }

  /// Get custom preset
  static List<String>? getCustomPreset(String model, FieldPreset preset) {
    return _customPresets[model]?[preset];
  }

  /// Clear all custom presets
  static void clearCustomPresets() {
    _customPresets.clear();
  }
}
