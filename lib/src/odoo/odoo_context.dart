/// Global context manager for Odoo operations
///
/// Manages default context values that are automatically included
/// in all Odoo calls (language, timezone, company, etc.)
///
/// Example:
/// ```dart
/// // Set default context at app startup
/// OdooContext.setDefault(
///   lang: 'ar_001',
///   timezone: 'Asia/Riyadh',
///   allowedCompanyIds: [1],
/// );
///
/// // Context will be automatically merged in all calls
/// await odoo.custom.callMethod(...);
/// ```
class OdooContext {
  static Map<String, dynamic>? _defaultContext;

  /// Set default context for all Odoo operations
  ///
  /// Parameters:
  /// - [lang]: Language code (e.g., 'ar_001', 'en_US')
  /// - [timezone]: Timezone (e.g., 'Asia/Riyadh', 'UTC')
  /// - [allowedCompanyIds]: List of allowed company IDs for multi-company
  /// - [uid]: User ID (usually set automatically after login)
  /// - [custom]: Additional custom context parameters
  static void setDefault({
    String? lang,
    String? timezone,
    List<int>? allowedCompanyIds,
    int? uid,
    Map<String, dynamic>? custom,
  }) {
    _defaultContext = {
      if (lang != null) 'lang': lang,
      if (timezone != null) 'tz': timezone,
      if (allowedCompanyIds != null)
        'allowed_company_ids': allowedCompanyIds,
      if (uid != null) 'uid': uid,
      ...?custom,
    };
  }

  /// Get current default context
  static Map<String, dynamic>? get defaultContext => _defaultContext;

  /// Merge provided context with default context
  ///
  /// Provided context takes precedence over default context
  static Map<String, dynamic>? merge(Map<String, dynamic>? context) {
    if (_defaultContext == null && context == null) {
      return null;
    }

    return {
      ...?_defaultContext,
      ...?context,
    };
  }

  /// Clear default context
  static void clear() {
    _defaultContext = null;
  }

  /// Update specific context values without replacing all
  static void update({
    String? lang,
    String? timezone,
    List<int>? allowedCompanyIds,
    int? uid,
    Map<String, dynamic>? custom,
  }) {
    _defaultContext = {
      ...?_defaultContext,
      if (lang != null) 'lang': lang,
      if (timezone != null) 'tz': timezone,
      if (allowedCompanyIds != null)
        'allowed_company_ids': allowedCompanyIds,
      if (uid != null) 'uid': uid,
      ...?custom,
    };
  }

  /// Set language only
  static void setLanguage(String lang) {
    update(lang: lang);
  }

  /// Set timezone only
  static void setTimezone(String timezone) {
    update(timezone: timezone);
  }

  /// Set allowed companies only
  static void setAllowedCompanies(List<int> companyIds) {
    update(allowedCompanyIds: companyIds);
  }
}
