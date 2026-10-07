import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/sales_provider.dart';
import '../../models/sales_order_model.dart';
import '../../utils/palette.dart';

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = const SalesQuery();
    final salesAsyncValue = ref.watch(salesListProvider(query));

    return Scaffold(
      backgroundColor: palette.white,
      appBar: AppBar(
        title: const Text('Sales Orders'),
        backgroundColor: palette.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => ref.refresh(salesListProvider(query)),
          ),
        ],
      ),
      body: salesAsyncValue.when(
        data: (salesOrders) {
          if (salesOrders.isEmpty) {
            return const Center(child: Text('No sales orders found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: salesOrders.length,
            itemBuilder: (context, index) {
              final order = salesOrders[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE2F0CB),
                    child: Icon(Icons.attach_money, color: Color(0xFF7CB342)),
                  ),
                  title: Text(
                    order.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${order.partnerId?.name ?? 'No Customer'} • ${order.dateOrder?.split(' ').first ?? ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${order.amountTotal?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStateBadge(order.state),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildStateBadge(String? state) {
    Color color;
    String label;
    switch (state) {
      case 'draft':
        color = Colors.grey;
        label = 'Quotation';
        break;
      case 'sent':
        color = Colors.blue;
        label = 'Quotation Sent';
        break;
      case 'sale':
        color = Colors.green;
        label = 'Sales Order';
        break;
      case 'done':
        color = Colors.purple;
        label = 'Locked';
        break;
      case 'cancel':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.black54;
        label = state ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
