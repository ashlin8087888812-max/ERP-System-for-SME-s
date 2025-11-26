import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/metric_tile.dart';
import '../../../../widgets/status_chip.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDimensions.p16,
              crossAxisSpacing: AppDimensions.p16,
              childAspectRatio: 1.5,
              children: const [
                MetricTile(
                  label: 'Active Jobs',
                  value: '12',
                  icon: Icons.work_outline,
                  color: AppColors.accent,
                ),
                MetricTile(
                  label: 'Workers Online',
                  value: '28',
                  icon: Icons.people_outline,
                  color: AppColors.success,
                  trend: '+3',
                  isPositiveTrend: true,
                ),
                MetricTile(
                  label: 'Warehouse Throughput',
                  value: '847',
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.info,
                  trend: '+12%',
                  isPositiveTrend: true,
                ),
                MetricTile(
                  label: 'Material Availability',
                  value: '94%',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p24),

            // Live Job Stages
            Text(
              'Live Job Stages',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildJobStageItem(
                    jobId: 'WO-2024-089',
                    stage: 'Assembly',
                    worker: 'John Doe',
                    progress: 0.65,
                    status: ChipStatus.warning,
                  ),
                  const Divider(),
                  _buildJobStageItem(
                    jobId: 'WO-2024-088',
                    stage: 'Welding',
                    worker: 'Jane Smith',
                    progress: 0.85,
                    status: ChipStatus.success,
                  ),
                  const Divider(),
                  _buildJobStageItem(
                    jobId: 'WO-2024-087',
                    stage: 'Quality Check',
                    worker: 'Mike Johnson',
                    progress: 0.30,
                    status: ChipStatus.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Worker Performance
            Text(
              'Worker Performance',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildWorkerPerformanceItem(
                    name: 'John Doe',
                    jobsCompleted: 8,
                    efficiency: 92,
                    status: ChipStatus.success,
                  ),
                  const Divider(),
                  _buildWorkerPerformanceItem(
                    name: 'Jane Smith',
                    jobsCompleted: 12,
                    efficiency: 95,
                    status: ChipStatus.success,
                  ),
                  const Divider(),
                  _buildWorkerPerformanceItem(
                    name: 'Mike Johnson',
                    jobsCompleted: 6,
                    efficiency: 78,
                    status: ChipStatus.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobStageItem({
    required String jobId,
    required String stage,
    required String worker,
    required double progress,
    required ChipStatus status,
  }) {
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
                  Text(jobId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(stage, style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
                ],
              ),
              StatusChip(label: status.name, status: status),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(worker, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.r4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.p8),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerPerformanceItem({
    required String name,
    required int jobsCompleted,
    required int efficiency,
    required ChipStatus status,
  }) {
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
                Text('$jobsCompleted jobs completed', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$efficiency%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              StatusChip(label: 'Efficiency', status: status),
            ],
          ),
        ],
      ),
    );
  }
}
