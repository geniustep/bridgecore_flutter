/// Request model for load_views operation (Odoo ≤15)
///
/// Loads multiple views at once for efficiency
class LoadViewsRequest {
  /// Model name
  final String model;

  /// List of [view_id, view_type] pairs
  /// Example: [[false, 'form'], [false, 'tree']]
  final List<List<dynamic>> views;

  /// Load action
  final bool loadAction;

  /// Load filters
  final bool loadFilters;

  LoadViewsRequest({
    required this.model,
    required this.views,
    this.loadAction = false,
    this.loadFilters = false,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'views': views,
        'options': {
          'load_action': loadAction,
          'load_filters': loadFilters,
        },
      };
}

