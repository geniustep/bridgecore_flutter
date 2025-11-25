import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class PermissionsDemo extends StatefulWidget {
  const PermissionsDemo({super.key});

  @override
  State<PermissionsDemo> createState() => _PermissionsDemoState();
}

class _PermissionsDemoState extends State<PermissionsDemo> {
  Map<String, bool> permissions = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => isLoading = true);

    try {
      final canRead =
          await BridgeCore.instance.odoo.permissions.checkAccessRights(
        model: 'sale.order',
        operation: 'read',
      );

      final canWrite =
          await BridgeCore.instance.odoo.permissions.checkAccessRights(
        model: 'sale.order',
        operation: 'write',
      );

      final canCreate =
          await BridgeCore.instance.odoo.permissions.checkAccessRights(
        model: 'sale.order',
        operation: 'create',
      );

      final canDelete =
          await BridgeCore.instance.odoo.permissions.checkAccessRights(
        model: 'sale.order',
        operation: 'unlink',
      );

      setState(() {
        permissions = {
          'read': canRead.hasAccess ?? false,
          'write': canWrite.hasAccess ?? false,
          'create': canCreate.hasAccess ?? false,
          'delete': canDelete.hasAccess ?? false,
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Demo'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Order Permissions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildPermissionTile(
                            'Read', permissions['read'] ?? false),
                        _buildPermissionTile(
                            'Write', permissions['write'] ?? false),
                        _buildPermissionTile(
                            'Create', permissions['create'] ?? false),
                        _buildPermissionTile(
                            'Delete', permissions['delete'] ?? false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (permissions['read'] == true)
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('View Orders'),
                          ),
                        const SizedBox(height: 8),
                        if (permissions['create'] == true)
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Create Order'),
                          ),
                        const SizedBox(height: 8),
                        if (permissions['write'] == true)
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Edit Order'),
                          ),
                        const SizedBox(height: 8),
                        if (permissions['delete'] == true)
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Delete Order'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionTile(String operation, bool hasAccess) {
    return ListTile(
      leading: Icon(
        hasAccess ? Icons.check_circle : Icons.cancel,
        color: hasAccess ? Colors.green : Colors.red,
      ),
      title: Text(operation),
      trailing: Text(
        hasAccess ? 'Allowed' : 'Denied',
        style: TextStyle(
          color: hasAccess ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
