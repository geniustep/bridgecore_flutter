// Main class
export 'src/bridgecore.dart';

// Auth
export 'src/auth/auth_service.dart';
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

// Core
export 'src/core/exceptions.dart';
export 'src/core/endpoints.dart';
export 'src/core/cache_manager.dart';
export 'src/core/logger.dart';
export 'src/core/metrics.dart';

// Client (optional - for advanced users)
export 'src/client/retry_interceptor.dart';
