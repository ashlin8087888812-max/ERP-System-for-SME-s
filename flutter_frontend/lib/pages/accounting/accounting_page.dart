import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/accounting_provider.dart';
import '../../models/invoice_model.dart';
import '../../utils/palette.dart';

class AccountingPage extends ConsumerWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = const AccountingQuery();
    final invoiceAsyncValue = ref.watch(invoiceListProvider(query));

    return Scaffold(
      backgroundColor: palette.white,
      appBar: AppBar(
        title: const Text('Invoices'),
        backgroundColor: palette.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => ref.refresh(invoiceListProvider(query)),
          ),
        ],
      ),
      body: invoiceAsyncValue.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(child: Text('No invoices found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFDAB9),
                    child: Icon(Icons.receipt_long, color: Color(0xFFFF7B25)),
                  ),
                  title: Text(
                    invoice.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${invoice.partnerId?.name ?? 'No Customer'} • ${invoice.invoiceDate ?? ''}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${invoice.amountTotal?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStateBadge(invoice.state),
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
        label = 'Draft';
        break;
      case 'posted':
        color = Colors.blue;
        label = 'Posted';
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
