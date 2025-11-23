/// Request model for get_views operation (Odoo 16+)
///
/// Modern replacement for load_views
class GetViewsRequest {
  /// Model name
  final String model;

  /// List of [view_id, view_type] pairs
  /// Example: [[false, 'form'], [false, 'list']]
  final List<List<dynamic>> views;

  /// Additional options
  final Map<String, dynamic>? options;

  GetViewsRequest({
    required this.model,
    required this.views,
    this.options,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'views': views,
        if (options != null) 'options': options,
      };
}

