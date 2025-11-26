import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class WorkerDashboard extends StatelessWidget {
  const WorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Navigate to scanner
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          // Active Job Card
          IndustrialCard(
            padding: const EdgeInsets.all(AppDimensions.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Job',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    StatusChip(label: 'In Progress', status: ChipStatus.warning),
                  ],
                ),
                const SizedBox(height: AppDimensions.p12),
                Text(
                  'WO-2024-089',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppDimensions.p8),
                const Text(
                  'Assembly Stage - Main Unit',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppDimensions.p16),
                
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progress', style: TextStyle(fontSize: 12)),
                        Text('65%', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.p8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.r4),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 8,
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.p16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text('Scan Material'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.p12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.go('/production/stage');
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text('Complete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.p24),
          
          // Assigned Jobs Section
          Text(
            'Assigned Jobs',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.p12),
          
          _buildJobCard(
            jobId: 'WO-2024-090',
            stage: 'Welding Stage',
            status: ChipStatus.neutral,
            statusLabel: 'Pending',
            priority: 'High',
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildJobCard(
            jobId: 'WO-2024-088',
            stage: 'Quality Check',
            status: ChipStatus.info,
            statusLabel: 'Ready',
            priority: 'Medium',
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildJobCard(
            jobId: 'WO-2024-087',
            stage: 'Packaging',
            status: ChipStatus.info,
            statusLabel: 'Ready',
            priority: 'Low',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to scanner
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Job'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildJobCard({
    required String jobId,
    required String stage,
    required ChipStatus status,
    required String statusLabel,
    required String priority,
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
            child: const Icon(Icons.work_outline, color: AppColors.accent),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jobId,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  stage,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusChip(label: statusLabel, status: status),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.p8,
                        vertical: AppDimensions.p4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.r4),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(priority),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.textSecondaryLight;
    }
  }
}
