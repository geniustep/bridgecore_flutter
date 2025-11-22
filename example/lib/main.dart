import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

void main() {
  // Initialize BridgeCore
  BridgeCore.initialize(
    baseUrl: 'https://api.yourdomain.com',
    debugMode: true,
    enableCache: true,
    enableLogging: true,
    logLevel: LogLevel.info,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgeCore Flutter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Not logged in';
  List<Map<String, dynamic>> _partners = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await BridgeCore.instance.auth.isLoggedIn;
    setState(() {
      _status = isLoggedIn ? 'Logged in' : 'Not logged in';
    });
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final session = await BridgeCore.instance.auth.login(
        email: 'user@company.com',
        password: 'password123',
      );

      if (!mounted) return;
      setState(() {
        _status = 'Logged in as: ${session.user.fullName}';
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    try {
      final partners = await BridgeCore.instance.odoo.searchRead(
        model: 'res.partner',
        domain: [
          ['is_company', '=', true]
        ],
        preset: FieldPreset.standard,
        useSmartFallback: true,
        limit: 50,
      );

      if (!mounted) return;
      setState(() {
        _partners = partners;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createPartner() async {
    setState(() => _loading = true);
    try {
      final id = await BridgeCore.instance.odoo.create(
        model: 'res.partner',
        values: {
          'name': 'New Company ${DateTime.now().millisecondsSinceEpoch}',
          'email': 'info@company.com',
          'is_company': true,
        },
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created partner with ID: $id')),
      );

      // Reload partners
      _loadPartners();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _batchCreate() async {
    setState(() => _loading = true);
    try {
      final ids = await BridgeCore.instance.odoo.batchCreate(
        model: 'res.partner',
        valuesList: [
          {'name': 'Batch Company 1', 'is_company': true},
          {'name': 'Batch Company 2', 'is_company': true},
          {'name': 'Batch Company 3', 'is_company': true},
        ],
      );

      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created ${ids.length} partners')),
      );

      // Reload partners
      _loadPartners();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showMetrics() async {
    final metrics = BridgeCore.instance.getMetrics();
    final cacheStats = BridgeCore.instance.getCacheStats();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metrics & Cache Stats'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Metrics:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total Requests: ${metrics['total_requests']}'),
              Text('Successful: ${metrics['successful_requests']}'),
              Text('Failed: ${metrics['failed_requests']}'),
              Text(
                  'Success Rate: ${(metrics['success_rate'] * 100).toStringAsFixed(1)}%'),
              Text(
                  'Avg Duration: ${metrics['average_duration_ms']?.toStringAsFixed(0)}ms'),
              const SizedBox(height: 16),
              Text('Cache:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total Entries: ${cacheStats['total_entries']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BridgeCore Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showMetrics,
            tooltip: 'Show Metrics',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: $_status',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _login,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Odoo Operations',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadPartners,
                            child: const Text('Load Partners'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _createPartner,
                            child: const Text('Create Partner'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _batchCreate,
                            child: const Text('Batch Create Partners'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_partners.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Partners:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._partners.map((partner) => Card(
                          child: ListTile(
                            title: Text(partner['name'] ?? 'N/A'),
                            subtitle: Text(partner['email'] ?? 'No email'),
                            trailing: Text('#${partner['id']}'),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}
