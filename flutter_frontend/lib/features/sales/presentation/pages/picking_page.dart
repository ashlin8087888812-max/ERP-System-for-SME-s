import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class PickingPage extends StatefulWidget {
  const PickingPage({super.key});

  @override
  State<PickingPage> createState() => _PickingPageState();
}

class _PickingPageState extends State<PickingPage> {
  final List<Map<String, dynamic>> _pickingItems = [
    {
      'itemCode': 'ITEM-001',
      'name': 'Steel Rods 12mm',
      'required': 50,
      'picked': 50,
      'location': 'A-12-3',
      'status': 'complete',
    },
    {
      'itemCode': 'ITEM-002',
      'name': 'Aluminum Sheets',
      'required': 30,
      'picked': 28,
      'location': 'A-15-2',
      'status': 'partial',
    },
    {
      'itemCode': 'ITEM-003',
      'name': 'Finished Product A',
      'required': 20,
      'picked': 0,
      'location': 'B-03-1',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalItems = _pickingItems.length;
    final completedItems = _pickingItems.where((item) => item['status'] == 'complete').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Picking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Order Info Header
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
                      'SO-2024-045',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    StatusChip(label: 'Picking', status: ChipStatus.warning),
                  ],
                ),
                const SizedBox(height: AppDimensions.p8),
                const Text(
                  'ABC Manufacturing Ltd.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppDimensions.p12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile('Total Items', '$totalItems'),
                    ),
                    Expanded(
                      child: _buildInfoTile('Picked', '$completedItems'),
                    ),
                    Expanded(
                      child: _buildInfoTile('Remaining', '${totalItems - completedItems}'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.r4),
                  child: LinearProgressIndicator(
                    value: completedItems / totalItems,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),

          // Picking List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.p16),
              itemCount: _pickingItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.p12),
              itemBuilder: (context, index) {
                final item = _pickingItems[index];
                return _buildPickingItemCard(
                  itemCode: item['itemCode'],
                  name: item['name'],
                  required: item['required'],
                  picked: item['picked'],
                  location: item['location'],
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
                    onPressed: () {},
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
                    onPressed: completedItems == totalItems ? () {} : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
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

  Widget _buildPickingItemCard({
    required String itemCode,
    required String name,
    required int required,
    required int picked,
    required String location,
    required String status,
  }) {
    final isComplete = status == 'complete';
    final isPartial = status == 'partial';
    final isPending = status == 'pending';

    ChipStatus chipStatus;
    String chipLabel;
    if (isComplete) {
      chipStatus = ChipStatus.success;
      chipLabel = 'Complete';
    } else if (isPartial) {
      chipStatus = ChipStatus.warning;
      chipLabel = 'Partial';
    } else {
      chipStatus = ChipStatus.neutral;
      chipLabel = 'Pending';
    }

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
                itemCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StatusChip(label: chipLabel, status: chipStatus),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Text(
            name,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                'Location: $location',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      '$required',
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
                      'Picked',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      '$picked',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? AppColors.success : (isPartial ? AppColors.warning : AppColors.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isComplete)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                  onPressed: () {
                    // Show dialog to manually enter quantity
                  },
                ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: AppDimensions.p12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.r4),
              child: LinearProgressIndicator(
                value: picked / required,
                minHeight: 6,
                backgroundColor: AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPartial ? AppColors.warning : AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
