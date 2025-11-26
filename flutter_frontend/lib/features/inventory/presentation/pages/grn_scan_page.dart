import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class GRNScanPage extends StatefulWidget {
  const GRNScanPage({super.key});

  @override
  State<GRNScanPage> createState() => _GRNScanPageState();
}

class _GRNScanPageState extends State<GRNScanPage> {
  final List<Map<String, dynamic>> _scannedItems = [
    {
      'itemCode': 'ITEM-001',
      'name': 'Steel Rods 12mm',
      'expectedQty': 100,
      'receivedQty': 100,
      'status': 'complete',
    },
    {
      'itemCode': 'ITEM-002',
      'name': 'Aluminum Sheets',
      'expectedQty': 50,
      'receivedQty': 48,
      'status': 'partial',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRN - Goods Receipt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // PO Info Header
          Container(
            color: AppColors.accent.withOpacity(0.1),
            padding: const EdgeInsets.all(AppDimensions.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PO-2024-001',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    StatusChip(label: 'In Progress', status: ChipStatus.warning),
                  ],
                ),
                const SizedBox(height: AppDimensions.p8),
                const Text(
                  'ABC Suppliers Ltd.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile('Expected', '15 items'),
                    ),
                    Expanded(
                      child: _buildInfoTile('Scanned', '2 items'),
                    ),
                    Expanded(
                      child: _buildInfoTile('Remaining', '13 items'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scanned Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.p16),
              itemCount: _scannedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.p12),
              itemBuilder: (context, index) {
                final item = _scannedItems[index];
                return _buildScannedItemCard(
                  itemCode: item['itemCode'],
                  name: item['name'],
                  expectedQty: item['expectedQty'],
                  receivedQty: item['receivedQty'],
                  status: item['status'],
                );
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppDimensions.p16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to scanner
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Item'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.p12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete GRN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildScannedItemCard({
    required String itemCode,
    required String name,
    required int expectedQty,
    required int receivedQty,
    required String status,
  }) {
    final isComplete = status == 'complete';
    final isPartial = status == 'partial';

    return IndustrialCard(
      padding: const EdgeInsets.all(AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                itemCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StatusChip(
                label: isComplete ? 'Complete' : 'Partial',
                status: isComplete ? ChipStatus.success : ChipStatus.warning,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Text(
            name,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      '$expectedQty',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Received',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      '$receivedQty',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPartial)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accent),
                  onPressed: () {
                    // Show dialog to adjust quantity
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
