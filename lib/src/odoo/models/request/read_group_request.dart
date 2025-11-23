/// Request model for read_group operation
///
/// Read group is used for aggregating data, essential for:
/// - Reports and analytics
/// - Dashboard statistics
/// - Grouped lists
/// - Charts and graphs
class ReadGroupRequest {
  /// Model name (e.g., 'sale.order')
  final String model;

  /// Domain filter
  final List<dynamic> domain;

  /// Fields to aggregate
  final List<String> fields;

  /// Fields to group by
  final List<String> groupby;

  /// Offset for pagination
  final int? offset;

  /// Limit number of groups
  final int? limit;

  /// Order by clause
  final String? orderby;

  /// Lazy grouping (only first level)
  final bool lazy;

  ReadGroupRequest({
    required this.model,
    this.domain = const [],
    required this.fields,
    required this.groupby,
    this.offset,
    this.limit,
    this.orderby,
    this.lazy = true,
  });

  Map<String, dynamic> toJson() => {
        'model': model,
        'domain': domain,
        'fields': fields,
        'groupby': groupby,
        if (offset != null) 'offset': offset,
        if (limit != null) 'limit': limit,
        if (orderby != null) 'orderby': orderby,
        'lazy': lazy,
      };
}

