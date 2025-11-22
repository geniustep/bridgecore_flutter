import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

/// Demo page for error handling with new exceptions
class ErrorHandlingDemo extends StatefulWidget {
  const ErrorHandlingDemo({super.key});

  @override
  State<ErrorHandlingDemo> createState() => _ErrorHandlingDemoState();
}

class _ErrorHandlingDemoState extends State<ErrorHandlingDemo> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorType;
  String? _errorMessage;
  Map<String, dynamic>? _errorDetails;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _loading = true;
      _errorType = null;
      _errorMessage = null;
      _errorDetails = null;
    });

    try {
      await BridgeCore.instance.auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } on PaymentRequiredException catch (e) {
      _handleError('PaymentRequiredException', e);
    } on AccountDeletedException catch (e) {
      _handleError('AccountDeletedException', e);
    } on TenantSuspendedException catch (e) {
      _handleError('TenantSuspendedException', e);
    } on UnauthorizedException catch (e) {
      _handleError('UnauthorizedException', e);
    } on ForbiddenException catch (e) {
      _handleError('ForbiddenException', e);
    } on ValidationException catch (e) {
      _handleError('ValidationException', e);
    } on NetworkException catch (e) {
      _handleError('NetworkException', e);
    } on BridgeCoreException catch (e) {
      _handleError('BridgeCoreException', e);
    }
  }

  void _handleError(String type, BridgeCoreException e) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _errorType = type;
      _errorMessage = e.message;
      _errorDetails = e.toMap();
    });
  }

  void _simulateError(String type) {
    switch (type) {
      case '401':
        _emailController.text = 'wrong@email.com';
        _passwordController.text = 'wrongpassword';
        break;
      case '402':
        // This would need a real expired trial account
        _emailController.text = 'expired@trial.com';
        _passwordController.text = 'password';
        break;
      case '403':
        // This would need a suspended account
        _emailController.text = 'suspended@account.com';
        _passwordController.text = 'password';
        break;
      case '410':
        // This would need a deleted account
        _emailController.text = 'deleted@account.com';
        _passwordController.text = 'password';
        break;
    }
    _testLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Demo'),
      ),
      body: SingleChildScrollView(
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
                          'New Exception Types',
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
                      'BridgeCore SDK now supports additional exception types:\n\n'
                      '• PaymentRequiredException (402) - Trial expired\n'
                      '• AccountDeletedException (410) - Account deleted\n'
                      '• TenantSuspendedException (403) - Account suspended\n'
                      '• UnauthorizedException (401) - Invalid credentials\n'
                      '• And more...',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Test Scenarios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _simulateError('401'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('401 Unauthorized'),
                        ),
                        ElevatedButton(
                          onPressed: () => _simulateError('402'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          child: const Text('402 Payment Required'),
                        ),
                        ElevatedButton(
                          onPressed: () => _simulateError('403'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('403 Suspended'),
                        ),
                        ElevatedButton(
                          onPressed: () => _simulateError('410'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('410 Deleted'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Test Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Manual Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _testLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test Login'),
                    ),
                  ],
                ),
              ),
            ),

            // Error Display
            if (_errorType != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _getErrorColor(_errorType!),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getErrorIcon(_errorType!),
                            color: _getErrorIconColor(_errorType!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorType!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getErrorIconColor(_errorType!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const Text(
                        'Message:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_errorMessage ?? 'No message'),
                      const SizedBox(height: 12),
                      const Text(
                        'Details:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _errorDetails?.entries.map((entry) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style:
                                        const TextStyle(fontFamily: 'monospace'),
                                  ),
                                );
                              }).toList() ??
                              [],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecommendedAction(_errorType!),
                    ],
                  ),
                ),
              ),
            ],

            // Exception Types Reference
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exception Types Reference',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildExceptionInfo(
                      '401',
                      'UnauthorizedException',
                      'Invalid or expired credentials',
                      'Ask user to login again',
                    ),
                    _buildExceptionInfo(
                      '402',
                      'PaymentRequiredException',
                      'Trial period has expired',
                      'Show upgrade/payment screen',
                    ),
                    _buildExceptionInfo(
                      '403',
                      'TenantSuspendedException',
                      'Account is suspended',
                      'Contact support message',
                    ),
                    _buildExceptionInfo(
                      '410',
                      'AccountDeletedException',
                      'Account has been deleted',
                      'Show account deleted message',
                    ),
                    _buildExceptionInfo(
                      '400',
                      'ValidationException',
                      'Invalid request data',
                      'Show validation errors',
                    ),
                    _buildExceptionInfo(
                      '404',
                      'NotFoundException',
                      'Resource not found',
                      'Handle missing resource',
                    ),
                    _buildExceptionInfo(
                      '500',
                      'ServerException',
                      'Server error',
                      'Show retry option',
                    ),
                    _buildExceptionInfo(
                      'N/A',
                      'NetworkException',
                      'Network connectivity issue',
                      'Check internet connection',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExceptionInfo(
    String code,
    String name,
    String description,
    String action,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 13)),
          Text(
            '→ $action',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedAction(String errorType) {
    String action;
    IconData icon;
    Color color;

    switch (errorType) {
      case 'PaymentRequiredException':
        action = 'Show upgrade screen and payment options';
        icon = Icons.payment;
        color = Colors.purple;
        break;
      case 'AccountDeletedException':
        action = 'Show account deleted message and contact support';
        icon = Icons.delete_forever;
        color = Colors.grey;
        break;
      case 'TenantSuspendedException':
        action = 'Show suspension message and support contact';
        icon = Icons.block;
        color = Colors.red;
        break;
      case 'UnauthorizedException':
        action = 'Clear tokens and redirect to login screen';
        icon = Icons.login;
        color = Colors.orange;
        break;
      default:
        action = 'Handle error appropriately';
        icon = Icons.error;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Action:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(action),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getErrorColor(String errorType) {
    switch (errorType) {
      case 'PaymentRequiredException':
        return Colors.purple.shade50;
      case 'AccountDeletedException':
        return Colors.grey.shade200;
      case 'TenantSuspendedException':
        return Colors.red.shade50;
      case 'UnauthorizedException':
        return Colors.orange.shade50;
      default:
        return Colors.red.shade50;
    }
  }

  IconData _getErrorIcon(String errorType) {
    switch (errorType) {
      case 'PaymentRequiredException':
        return Icons.payment;
      case 'AccountDeletedException':
        return Icons.delete_forever;
      case 'TenantSuspendedException':
        return Icons.block;
      case 'UnauthorizedException':
        return Icons.lock;
      default:
        return Icons.error;
    }
  }

  Color _getErrorIconColor(String errorType) {
    switch (errorType) {
      case 'PaymentRequiredException':
        return Colors.purple.shade700;
      case 'AccountDeletedException':
        return Colors.grey.shade700;
      case 'TenantSuspendedException':
        return Colors.red.shade700;
      case 'UnauthorizedException':
        return Colors.orange.shade700;
      default:
        return Colors.red.shade700;
    }
  }
}

