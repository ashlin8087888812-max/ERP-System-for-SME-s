import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class JobCardPage extends StatelessWidget {
  const JobCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Header
            IndustrialCard(
              padding: const EdgeInsets.all(AppDimensions.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WO-2024-089',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      StatusChip(label: 'In Progress', status: ChipStatus.warning),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p8),
                  const Text(
                    'Assembly - Main Unit Production',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoTile('Quantity', '100 units'),
                      ),
                      Expanded(
                        child: _buildInfoTile('Completed', '65 units'),
                      ),
                      Expanded(
                        child: _buildInfoTile('Remaining', '35 units'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.p16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.r4),
                    child: const LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 8,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // BOM (Bill of Materials)
            Text(
              'Bill of Materials',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildBOMItem(
                    itemCode: 'ITEM-001',
                    name: 'Steel Rods 12mm',
                    required: 200,
                    consumed: 130,
                    unit: 'pcs',
                  ),
                  const Divider(),
                  _buildBOMItem(
                    itemCode: 'ITEM-002',
                    name: 'Aluminum Sheets',
                    required: 100,
                    consumed: 65,
                    unit: 'pcs',
                  ),
                  const Divider(),
                  _buildBOMItem(
                    itemCode: 'ITEM-003',
                    name: 'Fasteners',
                    required: 500,
                    consumed: 325,
                    unit: 'pcs',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Routing / Stages
            Text(
              'Production Stages',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            _buildStageCard(
              stageName: 'Cutting',
              status: ChipStatus.success,
              statusLabel: 'Completed',
              worker: 'John Doe',
              duration: '2h 30m',
            ),
            const SizedBox(height: AppDimensions.p12),
            _buildStageCard(
              stageName: 'Assembly',
              status: ChipStatus.warning,
              statusLabel: 'In Progress',
              worker: 'Jane Smith',
              duration: '1h 45m',
            ),
            const SizedBox(height: AppDimensions.p12),
            _buildStageCard(
              stageName: 'Quality Check',
              status: ChipStatus.neutral,
              statusLabel: 'Pending',
              worker: 'Unassigned',
              duration: '-',
            ),
            const SizedBox(height: AppDimensions.p24),

            // Assigned Workers
            Text(
              'Assigned Workers',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildWorkerItem('John Doe', 'Cutting Specialist'),
                  const Divider(),
                  _buildWorkerItem('Jane Smith', 'Assembly Technician'),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildBOMItem({
    required String itemCode,
    required String name,
    required int required,
    required int consumed,
    required String unit,
  }) {
    final progress = consumed / required;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
              Text(
                '$consumed / $required $unit',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required String stageName,
    required ChipStatus status,
    required String statusLabel,
    required String worker,
    required String duration,
  }) {
    return IndustrialCard(
      onTap: () {},
      padding: const EdgeInsets.all(AppDimensions.p16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.p12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r8),
            ),
            child: const Icon(Icons.engineering_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stageName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Text(worker, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(label: statusLabel, status: status),
              const SizedBox(height: 4),
              Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerItem(String name, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withOpacity(0.1),
            child: Text(
              name[0],
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
