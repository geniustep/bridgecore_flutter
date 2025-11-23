import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

/// Demo page for /me endpoint with Odoo fields check
class MeWithFieldsDemo extends StatefulWidget {
  const MeWithFieldsDemo({super.key});

  @override
  State<MeWithFieldsDemo> createState() => _MeWithFieldsDemoState();
}

class _MeWithFieldsDemoState extends State<MeWithFieldsDemo> {
  final _modelController = TextEditingController(text: 'res.users');
  final _fieldsController = TextEditingController(text: 'shuttle_role');
  TenantMeResponse? _response;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _modelController.dispose();
    _fieldsController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserInfo({bool withFields = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
    });

    try {
      final auth = BridgeCore.instance.auth;

      OdooFieldsCheck? fieldsCheck;
      if (withFields) {
        final fields = _fieldsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (fields.isNotEmpty) {
          fieldsCheck = OdooFieldsCheck(
            model: _modelController.text.trim(),
            listFields: fields,
          );
        }
      }

      final response = await auth.me(
        odooFieldsCheck: fieldsCheck,
        forceRefresh: true, // Always get fresh data for demo
      );

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('/me with Fields Check Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'About /me Endpoint',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The /me endpoint returns comprehensive user information including:\n'
                      '• User profile from BridgeCore\n'
                      '• Tenant information\n'
                      '• Odoo partner_id and employee_id\n'
                      '• Odoo groups and permissions\n'
                      '• Company information\n'
                      '• Optional custom Odoo fields',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fields Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom Odoo Fields (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Odoo Model',
                        hintText: 'e.g., res.users',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fieldsController,
                      decoration: const InputDecoration(
                        labelText: 'Fields (comma-separated)',
                        hintText: 'e.g., shuttle_role, phone, mobile',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _fetchUserInfo(withFields: false),
                    icon: const Icon(Icons.person),
                    label: const Text('Get Basic Info'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _fetchUserInfo(withFields: true),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Get with Fields'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Error Display
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),

            // Response Display
            if (_response != null) ...[
              _buildUserInfoCard(),
              const SizedBox(height: 12),
              _buildTenantInfoCard(),
              const SizedBox(height: 12),
              _buildOdooInfoCard(),
              const SizedBox(height: 12),
              _buildGroupsCard(),
              if (_response!.odooFieldsData != null && 
                  _response!.odooFieldsData!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildCustomFieldsCard(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final user = _response!.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'User Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('ID', user.id),
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Full Name', user.fullName),
            _buildInfoRow('Role', user.role),
            _buildInfoRow('Odoo User ID', user.odooUserId?.toString() ?? 'N/A'),
            _buildInfoRow('Created At', user.createdAt.toIso8601String()),
            _buildInfoRow('Last Login', user.lastLogin?.toIso8601String() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantInfoCard() {
    final tenant = _response!.tenant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Tenant Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Name', tenant.name),
            _buildInfoRow('Slug', tenant.slug),
            _buildInfoRow('Status', tenant.status),
            _buildInfoRow('Odoo URL', tenant.odooUrl),
            _buildInfoRow('Database', tenant.odooDatabase),
            _buildInfoRow('Odoo Version', tenant.odooVersion ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildOdooInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Odoo Account Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Partner ID', _response!.partnerId?.toString() ?? 'N/A'),
            _buildInfoRow(
              'Employee ID',
              _response!.employeeId?.toString() ?? 'N/A',
            ),
            _buildInfoRow('Is Admin', _response!.isAdmin ? 'Yes' : 'No'),
            _buildInfoRow(
              'Is Internal User',
              _response!.isInternalUser ? 'Yes' : 'No',
            ),
            _buildInfoRow(
              'Company IDs',
              _response!.companyIds.join(', '),
            ),
            _buildInfoRow(
              'Current Company ID',
              _response!.currentCompanyId?.toString() ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Odoo Groups (${_response!.groups.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _response!.groups.map((group) {
                return Chip(
                  label: Text(
                    group,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.purple.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFieldsCard() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Custom Odoo Fields',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            ...(_response!.odooFieldsData?.entries.map((entry) {
              return _buildInfoRow(entry.key, entry.value.toString());
            }) ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

