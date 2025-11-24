/// Represents an Odoo action result
///
/// When a button method returns an action (e.g., opening a form, wizard),
/// Odoo returns an action dictionary that describes what to do next.
///
/// Common action types in Odoo 18:
/// - ir.actions.act_window: Open a window (form, list, kanban)
/// - ir.actions.act_url: Open a URL
/// - ir.actions.client: Client-side action
/// - ir.actions.server: Server action
/// - ir.actions.report: Generate a report
class ActionResult {
  /// Action type
  final String type;

  /// Model name (for act_window)
  final String? resModel;

  /// View mode (form, list, kanban, etc.)
  final String? viewMode;

  /// Record ID (for form view)
  final int? resId;

  /// View IDs
  final List<dynamic>? views;

  /// Target (new, current, fullscreen)
  final String? target;

  /// Domain filter
  final List<dynamic>? domain;

  /// Context for the action
  final Map<String, dynamic>? context;

  /// Action name/title
  final String? name;

  /// URL (for act_url)
  final String? url;

  /// Report name (for reports)
  final String? reportName;

  /// Additional data
  final Map<String, dynamic>? data;

  /// Raw action dictionary
  final Map<String, dynamic> raw;

  ActionResult({
    required this.type,
    this.resModel,
    this.viewMode,
    this.resId,
    this.views,
    this.target,
    this.domain,
    this.context,
    this.name,
    this.url,
    this.reportName,
    this.data,
    required this.raw,
  });

  /// Check if this is a window action
  bool get isWindowAction => type == 'ir.actions.act_window';

  /// Check if this is a URL action
  bool get isUrlAction => type == 'ir.actions.act_url';

  /// Check if this is a report action
  bool get isReportAction => type == 'ir.actions.report';

  /// Check if this is a client action
  bool get isClientAction => type == 'ir.actions.client';

  /// Check if this is a server action
  bool get isServerAction => type == 'ir.actions.server';

  /// Check if action opens in new window
  bool get opensInNewWindow => target == 'new';

  /// Check if action opens in fullscreen
  bool get opensInFullscreen => target == 'fullscreen';

  /// Check if action is a form view
  bool get isFormView => viewMode?.contains('form') ?? false;

  /// Check if action is a list view
  bool get isListView => viewMode?.contains('list') ?? false;

  /// Check if action is a kanban view
  bool get isKanbanView => viewMode?.contains('kanban') ?? false;

  factory ActionResult.fromJson(Map<String, dynamic> json) {
    return ActionResult(
      type: json['type'] as String,
      resModel: json['res_model'] as String?,
      viewMode: json['view_mode'] as String?,
      resId: json['res_id'] as int?,
      views: json['views'] as List<dynamic>?,
      target: json['target'] as String?,
      domain: json['domain'] as List<dynamic>?,
      context: json['context'] as Map<String, dynamic>?,
      name: json['name'] as String?,
      url: json['url'] as String?,
      reportName: json['report_name'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;

  @override
  String toString() {
    return 'ActionResult(type: $type, resModel: $resModel, '
        'viewMode: $viewMode, resId: $resId, target: $target)';
  }
}

/// Extension to easily convert CallMethodResponse/CallKwResponse to ActionResult
extension ActionResultExtension on dynamic {
  /// Convert response to ActionResult if it contains an action
  ActionResult? toActionResult() {
    if (this == null) return null;

    // Check if this is a CallMethodResponse or CallKwResponse with action
    if (this is Map<String, dynamic>) {
      final map = this as Map<String, dynamic>;
      if (map.containsKey('type')) {
        return ActionResult.fromJson(map);
      }
    }

    // Check if response has action property
    try {
      final hasAction = (this as dynamic).action;
      if (hasAction is Map<String, dynamic>) {
        return ActionResult.fromJson(hasAction);
      }
    } catch (e) {
      // Not a response with action property
    }

    return null;
  }
}
