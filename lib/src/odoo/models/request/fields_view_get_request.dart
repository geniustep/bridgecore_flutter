/// Request model for fields_view_get operation (Odoo ≤15)
class FieldsViewGetRequest {
  /// Model name
  final String model;

  /// View ID (null for default view)
  final int? viewId;

  /// View type ('form', 'tree', 'kanban', etc.)
  final String viewType;

  /// Include toolbar
  final bool toolbar;

  /// Include submenu
  final bool submenu;

  FieldsViewGetRequest({
    required this.model,
    this.viewId,
    required this.viewType,
    this.toolbar = false,
    this.submenu = false,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        if (viewId != null) 'view_id': viewId,
        'view_type': viewType,
        'toolbar': toolbar,
        'submenu': submenu,
      };
}

