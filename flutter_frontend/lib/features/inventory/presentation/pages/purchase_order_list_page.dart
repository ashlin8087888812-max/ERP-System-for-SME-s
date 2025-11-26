import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class PurchaseOrderListPage extends StatelessWidget {
  const PurchaseOrderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          _buildPOCard(
            poNumber: 'PO-2024-001',
            supplier: 'ABC Suppliers Ltd.',
            items: 15,
            totalAmount: '₹1,25,000',
            status: ChipStatus.warning,
            statusLabel: 'Pending',
            date: '2024-11-20',
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildPOCard(
            poNumber: 'PO-2024-002',
            supplier: 'XYZ Materials Co.',
            items: 8,
            totalAmount: '₹75,500',
            status: ChipStatus.info,
            statusLabel: 'Approved',
            date: '2024-11-19',
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildPOCard(
            poNumber: 'PO-2024-003',
            supplier: 'Tech Components Inc.',
            items: 22,
            totalAmount: '₹2,45,000',
            status: ChipStatus.success,
            statusLabel: 'Received',
            date: '2024-11-18',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to create PO
        },
        icon: const Icon(Icons.add),
        label: const Text('New PO'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildPOCard({
    required String poNumber,
    required String supplier,
    required int items,
    required String totalAmount,
    required ChipStatus status,
    required String statusLabel,
    required String date,
  }) {
    return IndustrialCard(
      onTap: () {},
      padding: const EdgeInsets.all(AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                poNumber,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              StatusChip(label: statusLabel, status: status),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  supplier,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          const Divider(),
          const SizedBox(height: AppDimensions.p8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  Text(
                    '$items',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  Text(
                    totalAmount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
