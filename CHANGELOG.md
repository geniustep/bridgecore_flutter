# Changelog

## [2.0.0] - 2025-11-23

### Added - 🎉 Major Release
- **Advanced Operations (4 new)**
  - `onchange()` - Auto-calculate field values (CRITICAL for forms)
  - `readGroup()` - Aggregate data for reports and analytics
  - `defaultGet()` - Get default field values
  - `copy()` - Duplicate records

- **View Operations (4 new)**
  - `fieldsViewGet()` - Get view definition (Odoo ≤15)
  - `getView()` - Get view definition (Odoo 16+)
  - `loadViews()` - Load multiple views (Odoo ≤15)
  - `getViews()` - Load multiple views (Odoo 16+)

- **Permission Operations (2 new)**
  - `checkAccessRights()` - Check user permissions
  - `exists()` - Check if records exist

- **Name Operations (1 new)**
  - `nameCreate()` - Create record by name only

- **Custom Methods (5 new)**
  - `callMethod()` - Generic method caller
  - `actionConfirm()` - Confirm records
  - `actionCancel()` - Cancel records
  - `actionDraft()` - Set to draft
  - `actionPost()` - Post documents

- **27 New Files**
  - 5 operation classes
  - 11 request models
  - 11 response models

- **Enhanced `/me` Endpoint**
  - Added `meWithFieldsCheck` endpoint constant
  - Support for POST requests with custom Odoo fields
  - Retrieve user-specific Odoo fields dynamically
  - Example demo page for `/me` with fields check

### Changed
- Refactored to modular architecture
- All operations now have typed request/response models
- Updated `OdooService` to use operation classes
- Improved documentation with comprehensive examples
- Enhanced authentication with custom Odoo fields support

### Coverage
- **Before:** 17/26 operations (65%)
- **After:** 26/26 operations (100%) ✅

## [0.2.0] - 2024-11-XX

### Added
- Enhanced `/me` endpoint with Odoo data
- Odoo Fields Check feature
- PaymentRequired exception (402)
- AccountDeleted exception (410)

### Changed
- Improved error handling

## [0.1.0] - 2024-XX-XX

### Added
- Initial release
- Basic CRUD operations
- Search operations
- Authentication
- Token management
