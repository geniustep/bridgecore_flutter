import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

/// Demo page for Odoo Fields Check feature
///
/// Shows how to verify custom fields during login
class OdooFieldsCheckDemo extends StatefulWidget {
  const OdooFieldsCheckDemo({super.key});

  @override
  State<OdooFieldsCheckDemo> createState() => _OdooFieldsCheckDemoState();
}

class _OdooFieldsCheckDemoState extends State<OdooFieldsCheckDemo> {
  final _emailController = TextEditingController(text: 'admin@done.done');
  final _passwordController = TextEditingController(text: ',,07Genius');
  final _modelController = TextEditingController(text: 'res.users');
  final _fieldsController = TextEditingController(
    text: 'name,email,lang,tz,x_employee_code',
  );

  bool _loading = false;
  TenantSession? _session;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _modelController.dispose();
    _fieldsController.dispose();
    super.dispose();
  }

  Future<void> _loginWithFieldsCheck() async {
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
    });

    try {
      // Parse fields from comma-separated string
      final fields = _fieldsController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      // Create fields check request
      final fieldsCheck = OdooFieldsCheck(
        model: _modelController.text,
        listFields: fields,
      );

      // Login with fields check
      final session = await BridgeCore.instance.auth.login(
        email: _emailController.text,
        password: _passwordController.text,
        odooFieldsCheck: fieldsCheck,
      );

      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Check results below.'),
          backgroundColor: Colors.green,
        ),
      );
    } on PaymentRequiredException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Trial period expired: ${e.message}';
        _loading = false;
      });
    } on AccountDeletedException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Account deleted: ${e.message}';
        _loading = false;
      });
    } on TenantSuspendedException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Account suspended: ${e.message}';
        _loading = false;
      });
    } on UnauthorizedException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid credentials: ${e.message}';
        _loading = false;
      });
    } on BridgeCoreException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.message}';
        _loading = false;
      });
    }
  }

  Future<void> _loginNormal() async {
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
    });

    try {
      final session = await BridgeCore.instance.auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Normal login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Fields Check Demo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Odoo Fields Check',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This feature allows you to verify custom fields in Odoo '
                            'and fetch their values during login.\n\n'
                            'Use case: Verify employee code, department, or other '
                            'custom fields exist before proceeding.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Form
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Odoo Model',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., res.users',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _fieldsController,
                            decoration: const InputDecoration(
                              labelText: 'Fields to Check (comma-separated)',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., name,email,x_employee_code',
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loginWithFieldsCheck,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Login with Fields Check'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _loginNormal,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Normal Login'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error Display
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Results Display
                  if (_session != null) ...[
                    const SizedBox(height: 16),
                    _buildSessionInfo(),
                    if (_session!.odooFieldsData != null) ...[
                      const SizedBox(height: 16),
                      _buildFieldsCheckResult(),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('User', _session!.user.fullName),
            _buildInfoRow('Email', _session!.user.email),
            _buildInfoRow('Role', _session!.user.role),
            _buildInfoRow('Tenant', _session!.tenant.name),
            _buildInfoRow('Status', _session!.tenant.status),
            _buildInfoRow('Token Type', _session!.tokenType),
            _buildInfoRow('Expires In', '${_session!.expiresIn}s'),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldsCheckResult() {
    final fieldsData = _session!.odooFieldsData!;

    return Card(
      color: fieldsData.success ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  fieldsData.success ? Icons.check_circle : Icons.warning,
                  color: fieldsData.success ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Fields Check Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Success', fieldsData.success.toString()),
            _buildInfoRow('Model Exists', fieldsData.modelExists.toString()),
            if (fieldsData.modelName != null)
              _buildInfoRow('Model Name', fieldsData.modelName!),
            _buildInfoRow('Fields Exist', fieldsData.fieldsExist.toString()),

            // Fields Info
            if (fieldsData.fieldsInfo != null &&
                fieldsData.fieldsInfo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Fields Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...fieldsData.fieldsInfo!.entries.map((entry) {
                final field = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(field.name),
                    subtitle: Text('${field.fieldDescription} (${field.ttype})'),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  ),
                );
              }),
            ],

            // Fetched Data
            if (fieldsData.data != null && fieldsData.data!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Fetched Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fieldsData.data!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              entry.value?.toString() ?? 'null',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Error
            if (fieldsData.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fieldsData.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            width: 100,
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
}

