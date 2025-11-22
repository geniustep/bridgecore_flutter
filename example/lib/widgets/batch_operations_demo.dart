import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class BatchOperationsDemo extends StatefulWidget {
  const BatchOperationsDemo({super.key});

  @override
  State<BatchOperationsDemo> createState() => _BatchOperationsDemoState();
}

class _BatchOperationsDemoState extends State<BatchOperationsDemo> {
  bool _loading = false;
  String? _result;

  Future<void> _batchCreate() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final ids = await BridgeCore.instance.odoo.batchCreate(
        model: 'res.partner',
        valuesList: [
          {'name': 'Batch Company 1', 'is_company': true},
          {'name': 'Batch Company 2', 'is_company': true},
          {'name': 'Batch Company 3', 'is_company': true},
        ],
      );

      setState(() {
        _result = 'Created ${ids.length} partners with IDs: ${ids.join(", ")}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _batchUpdate() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      // First, get some partner IDs
      final ids = await BridgeCore.instance.odoo.search(
        model: 'res.partner',
        domain: [['is_company', '=', true]],
        limit: 3,
      );

      if (ids.isEmpty) {
        setState(() {
          _result = 'No partners found to update';
          _loading = false;
        });
        return;
      }

      await BridgeCore.instance.odoo.batchUpdate(
        model: 'res.partner',
        updates: ids.map((id) => {
          'id': id,
          'values': {'comment': 'Updated via batch operation'}
        }).toList(),
      );

      setState(() {
        _result = 'Updated ${ids.length} partners';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _executeBatch() async {
    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final results = await BridgeCore.instance.odoo.executeBatch([
        {
          'method': 'search_read',
          'model': 'res.partner',
          'domain': [['is_company', '=', true]],
          'fields': ['name', 'email'],
          'limit': 5,
        },
        {
          'method': 'search_count',
          'model': 'product.product',
          'domain': [],
        },
      ]);

      setState(() {
        _result = 'Batch executed successfully. Results: ${results.length}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Operations Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _batchCreate,
              child: const Text('Batch Create'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _batchUpdate,
              child: const Text('Batch Update'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _executeBatch,
              child: const Text('Execute Batch'),
            ),
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_result!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

