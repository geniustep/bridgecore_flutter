import 'package:flutter/material.dart';
import 'package:bridgecore_flutter/bridgecore_flutter.dart';

class AdvancedOperationsDemo extends StatefulWidget {
  const AdvancedOperationsDemo({Key? key}) : super(key: key);

  @override
  State<AdvancedOperationsDemo> createState() => _AdvancedOperationsDemoState();
}

class _AdvancedOperationsDemoState extends State<AdvancedOperationsDemo> {
  int? selectedProductId;
  double quantity = 1.0;
  double calculatedPrice = 0.0;
  double calculatedDiscount = 0.0;
  bool isLoading = false;
  List<Map<String, dynamic>> salesReport = [];

  Future<void> _onProductChanged(int? productId) async {
    if (productId == null) return;

    setState(() {
      selectedProductId = productId;
      isLoading = true;
    });

    try {
      final result = await BridgeCore.instance.odoo.advanced.onchange(
        model: 'sale.order.line',
        values: {
          'product_id': productId,
          'product_uom_qty': quantity,
        },
        field: 'product_id',
        spec: {
          'product_id': '1',
          'price_unit': '1',
          'discount': '1',
        },
      );

      if (result.success && result.value != null) {
        setState(() {
          calculatedPrice = result.value?['price_unit'] ?? 0.0;
          calculatedDiscount = result.value?['discount'] ?? 0.0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadSalesReport() async {
    setState(() => isLoading = true);

    try {
      final result = await BridgeCore.instance.odoo.advanced.readGroup(
        model: 'sale.order',
        domain: [
          ['state', '=', 'sale']
        ],
        fields: ['amount_total'],
        groupby: ['partner_id'],
        orderby: 'amount_total desc',
        limit: 10,
      );

      if (result.success && result.groups != null) {
        setState(() {
          salesReport = result.groups!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Operations Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Onchange Demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Onchange Demo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 1, child: Text('Product 1')),
                      DropdownMenuItem(value: 2, child: Text('Product 2')),
                      DropdownMenuItem(value: 3, child: Text('Product 3')),
                    ],
                    onChanged: _onProductChanged,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        quantity = double.tryParse(value) ?? 1.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ListTile(
                      title: const Text('Calculated Price'),
                      trailing: Text(
                        '\$${calculatedPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ListTile(
                      title: const Text('Calculated Discount'),
                      trailing: Text(
                        '${calculatedDiscount.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Read Group Demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Report (Read Group)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _loadSalesReport,
                    child: const Text('Load Report'),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (salesReport.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: salesReport.length,
                      itemBuilder: (context, index) {
                        final group = salesReport[index];
                        return ListTile(
                          title: Text(group['partner_id'][1]),
                          subtitle: Text('${group['partner_id_count']} orders'),
                          trailing: Text(
                            '\$${group['amount_total'].toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

