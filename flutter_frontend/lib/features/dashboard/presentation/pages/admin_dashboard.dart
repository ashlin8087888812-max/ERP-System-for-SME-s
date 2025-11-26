import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/metric_tile.dart';
import '../../../../widgets/status_chip.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDimensions.p16,
              crossAxisSpacing: AppDimensions.p16,
              childAspectRatio: 1.5,
              children: const [
                MetricTile(
                  label: 'Total Materials',
                  value: '1,247',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.info,
                  trend: '+12%',
                  isPositiveTrend: true,
                ),
                MetricTile(
                  label: 'Active Jobs',
                  value: '34',
                  icon: Icons.work_outline,
                  color: AppColors.accent,
                  trend: '+5',
                  isPositiveTrend: true,
                ),
                MetricTile(
                  label: 'Active Warehouses',
                  value: '8',
                  icon: Icons.warehouse_outlined,
                  color: AppColors.success,
                ),
                MetricTile(
                  label: 'Pending Orders',
                  value: '23',
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  trend: '-3',
                  isPositiveTrend: false,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.p24),

            // Recent Activity Section
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            IndustrialCard(
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'New Purchase Order',
                    subtitle: 'PO-2024-001 created',
                    time: '5 min ago',
                    status: ChipStatus.info,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'Goods Received',
                    subtitle: 'GRN-2024-045 completed',
                    time: '15 min ago',
                    status: ChipStatus.success,
                  ),
                  const Divider(),
                  _buildActivityItem(
                    icon: Icons.production_quantity_limits_outlined,
                    title: 'Production Started',
                    subtitle: 'Job #WO-2024-089',
                    time: '1 hour ago',
                    status: ChipStatus.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.p24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.p12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDimensions.p12,
              crossAxisSpacing: AppDimensions.p12,
              children: [
                _buildQuickAction(
                  context: context,
                  icon: Icons.add_shopping_cart,
                  label: 'New PO',
                  route: '/inventory/po',
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.person_add_outlined,
                  label: 'Add User',
                  route: null, // Coming soon
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.warehouse_outlined,
                  label: 'New Branch',
                  route: null, // Coming soon
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.inventory_outlined,
                  label: 'Stock Check',
                  route: '/inventory/stock',
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Reports',
                  route: null, // Coming soon
                ),
                _buildQuickAction(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: null, // Coming soon
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required ChipStatus status,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.p8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.p8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r8),
            ),
            child: Icon(icon, color: AppColors.accent, size: AppDimensions.iconMedium),
          ),
          const SizedBox(width: AppDimensions.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(label: status.name, status: status),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? route,
  }) {
    return IndustrialCard(
      onTap: () {
        if (route != null) {
          context.go(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label - Coming soon')),
          );
        }
      },
      padding: const EdgeInsets.all(AppDimensions.p12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: AppDimensions.iconLarge),
          const SizedBox(height: AppDimensions.p8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
