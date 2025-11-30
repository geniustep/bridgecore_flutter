// Main class
export 'src/bridgecore.dart';

// Auth
export 'src/auth/auth_service.dart';
export 'src/auth/token_manager.dart';
export 'src/auth/models/auth_tokens.dart';
export 'src/auth/models/login_request.dart';
export 'src/auth/models/tenant_session.dart';
export 'src/auth/models/user_info.dart';
export 'src/auth/models/odoo_fields_check.dart';
export 'src/auth/models/odoo_fields_data.dart';
export 'src/auth/models/tenant_me_response.dart';

// Odoo
export 'src/odoo/odoo_service.dart';
export 'src/odoo/field_presets.dart';
export 'src/odoo/field_fallback_strategy.dart';
export 'src/odoo/odoo_context.dart';

// Odoo Operations
export 'src/odoo/operations/advanced_operations.dart';
export 'src/odoo/operations/view_operations.dart';
export 'src/odoo/operations/permission_operations.dart';
export 'src/odoo/operations/name_operations.dart';
export 'src/odoo/operations/custom_operations.dart';

// Odoo Request Models
export 'src/odoo/models/request/onchange_request.dart';
export 'src/odoo/models/request/read_group_request.dart';
export 'src/odoo/models/request/default_get_request.dart';
export 'src/odoo/models/request/copy_request.dart';
export 'src/odoo/models/request/fields_view_get_request.dart';
export 'src/odoo/models/request/load_views_request.dart';
export 'src/odoo/models/request/get_views_request.dart';
export 'src/odoo/models/request/check_access_rights_request.dart';
export 'src/odoo/models/request/exists_request.dart';
export 'src/odoo/models/request/name_create_request.dart';
export 'src/odoo/models/request/call_method_request.dart';
export 'src/odoo/models/request/call_kw_request.dart';

// Odoo Response Models
export 'src/odoo/models/response/onchange_response.dart';
export 'src/odoo/models/response/read_group_response.dart';
export 'src/odoo/models/response/default_get_response.dart';
export 'src/odoo/models/response/copy_response.dart';
export 'src/odoo/models/response/fields_view_get_response.dart';
export 'src/odoo/models/response/load_views_response.dart';
export 'src/odoo/models/response/get_views_response.dart';
export 'src/odoo/models/response/check_access_rights_response.dart';
export 'src/odoo/models/response/exists_response.dart';
export 'src/odoo/models/response/name_create_response.dart';
export 'src/odoo/models/response/call_method_response.dart';
export 'src/odoo/models/response/call_kw_response.dart';

// Odoo Models
export 'src/odoo/models/action_result.dart';

// Core
export 'src/core/exceptions.dart';
export 'src/core/endpoints.dart';
export 'src/core/cache_manager.dart';
export 'src/core/logger.dart';
export 'src/core/metrics.dart';

// Client (optional - for advanced users)
export 'src/client/retry_interceptor.dart';

// Triggers
export 'src/triggers/trigger_service.dart';
export 'src/triggers/models/trigger.dart';
export 'src/triggers/models/trigger_execution.dart';

// Notifications
export 'src/notifications/notification_service.dart';
export 'src/notifications/models/notification.dart';
export 'src/notifications/models/notification_preference.dart';
export 'src/notifications/models/device_token.dart';

// Sync
export 'src/sync/sync_service.dart';

// Odoo Sync
export 'src/odoo_sync/odoo_sync_service.dart';

// Events
export 'src/events/event_bus.dart';
export 'src/events/event_types.dart';
export 'src/events/bridgecore_event.dart';
