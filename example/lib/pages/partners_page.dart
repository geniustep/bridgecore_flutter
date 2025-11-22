import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  List<Map<String, dynamic>> _partners = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final partners = await BridgeCore.instance.odoo.searchRead(
        model: 'res.partner',
        domain: [['is_company', '=', true]],
        preset: FieldPreset.standard,
        useSmartFallback: true,
        limit: 50,
      );

      setState(() {
        _partners = partners;
        _loading = false;
      });
    } on UnauthorizedException {
      setState(() {
        _error = 'Session expired. Please login again.';
        _loading = false;
      });
    } on NetworkException {
      setState(() {
        _error = 'No internet connection';
        _loading = false;
      });
    } on BridgeCoreException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
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
        title: const Text('Partners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPartners,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPartners,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _partners.isEmpty
                  ? const Center(child: Text('No partners found'))
                  : RefreshIndicator(
                      onRefresh: _loadPartners,
                      child: ListView.builder(
                        itemCount: _partners.length,
                        itemBuilder: (context, index) {
                          final partner = _partners[index];
                          return ListTile(
                            title: Text(partner['name'] ?? 'N/A'),
                            subtitle: Text(partner['email'] ?? 'No email'),
                            trailing: Text('#${partner['id']}'),
                            onTap: () {
                              // Navigate to partner details
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

