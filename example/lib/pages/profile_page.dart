import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

/// Profile page demonstrating the new /me endpoint
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TenantMeResponse? _userInfo;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch user info with optional custom fields
      final userInfo = await BridgeCore.instance.auth.me(
        forceRefresh: forceRefresh,
        odooFieldsCheck: OdooFieldsCheck(
          model: 'res.users',
          listFields: ['phone', 'mobile', 'signature'],
        ),
      );

      if (!mounted) return;
      setState(() {
        _userInfo = userInfo;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUserInfo(forceRefresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final user = _userInfo!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    user.user.fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        user.user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(user.user.role.toUpperCase()),
                            backgroundColor:
                                user.isAdmin ? Colors.red : Colors.blue,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          if (user.isEmployee)
                            const Chip(
                              label: Text('EMPLOYEE'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Tenant Info
        _buildSection(
          'Tenant Information',
          [
            _buildInfoRow('Name', user.tenant.name),
            _buildInfoRow('Database', user.tenant.odooDatabase),
            _buildInfoRow(
                'Odoo Version', user.tenant.odooVersion ?? 'N/A'),
            _buildInfoRow('Status', user.tenant.status.toUpperCase()),
          ],
        ),

        const SizedBox(height: 16),

        // Odoo Integration
        _buildSection(
          'Odoo Integration',
          [
            _buildInfoRow(
                'Partner ID', user.partnerId?.toString() ?? 'N/A'),
            _buildInfoRow('Employee ID',
                user.employeeId?.toString() ?? 'Not an employee'),
            _buildInfoRow('Is Admin', user.isAdmin ? 'Yes ✓' : 'No'),
            _buildInfoRow(
                'Internal User', user.isInternalUser ? 'Yes ✓' : 'No'),
            _buildInfoRow(
                'Multi-Company', user.isMultiCompany ? 'Yes ✓' : 'No'),
            _buildInfoRow('Companies', user.companyIds.join(', ')),
            if (user.currentCompanyId != null)
              _buildInfoRow(
                  'Current Company', user.currentCompanyId.toString()),
          ],
        ),

        const SizedBox(height: 16),

        // Permissions
        _buildSection(
          'Permissions & Groups',
          [
            _buildInfoRow('Total Groups', user.groups.length.toString()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.groups.map((group) {
                return Chip(
                  label: Text(
                    group.split('.').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Permission Checks
        _buildSection(
          'Permission Checks',
          [
            _buildPermissionRow(
                'Can Manage Partners', user.canManagePartners),
            _buildPermissionRow(
                'Has Multi-Company Access', user.hasMultiCompanyAccess),
            _buildPermissionRow(
                'Is System User', user.hasGroup(TenantMePermissions.groupSystem)),
            _buildPermissionRow(
                'Is ERP Manager', user.hasGroup(TenantMePermissions.groupErpManager)),
          ],
        ),

        // Custom Fields
        if (user.odooFieldsData != null &&
            user.odooFieldsData!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            'Custom Odoo Fields',
            user.odooFieldsData!.entries.map((entry) {
              return _buildInfoRow(entry.key, entry.value.toString());
            }).toList(),
          ),
        ],

        const SizedBox(height: 16),

        // Account Info
        _buildSection(
          'Account Information',
          [
            _buildInfoRow('User ID', user.user.id),
            _buildInfoRow('Odoo User ID',
                user.user.odooUserId?.toString() ?? 'N/A'),
            _buildInfoRow(
                'Created At', _formatDate(user.user.createdAt)),
            _buildInfoRow('Last Login',
                user.user.lastLogin != null ? _formatDate(user.user.lastLogin!) : 'Never'),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

