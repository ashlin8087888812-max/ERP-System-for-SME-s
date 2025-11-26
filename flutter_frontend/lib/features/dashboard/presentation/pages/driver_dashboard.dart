import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';
import '../../../../widgets/status_chip.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - Coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Preview (Placeholder)
          Container(
            height: 250,
            color: AppColors.borderLight,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 64, color: AppColors.textSecondaryLight),
                      const SizedBox(height: AppDimensions.p8),
                      Text(
                        'Map View',
                        style: TextStyle(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppDimensions.p16,
                  right: AppDimensions.p16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.p12,
                      vertical: AppDimensions.p8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.r8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GPS Active',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Delivery List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.p16),
              children: [
                Text(
                  'Today\'s Deliveries',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppDimensions.p12),
                
                _buildDeliveryCard(
                  context: context,
                  orderId: 'DO-2024-045',
                  customer: 'ABC Manufacturing Ltd.',
                  address: '123 Industrial Park, Sector 5',
                  items: 12,
                  status: ChipStatus.warning,
                  statusLabel: 'In Transit',
                  eta: '15 min',
                  isActive: true,
                ),
                const SizedBox(height: AppDimensions.p12),
                
                _buildDeliveryCard(
                  context: context,
                  orderId: 'DO-2024-046',
                  customer: 'XYZ Logistics Co.',
                  address: '456 Business District, Zone 3',
                  items: 8,
                  status: ChipStatus.neutral,
                  statusLabel: 'Pending',
                  eta: '45 min',
                  isActive: false,
                ),
                const SizedBox(height: AppDimensions.p12),
                
                _buildDeliveryCard(
                  context: context,
                  orderId: 'DO-2024-044',
                  customer: 'Tech Solutions Inc.',
                  address: '789 Tech Hub, Building A',
                  items: 5,
                  status: ChipStatus.success,
                  statusLabel: 'Delivered',
                  eta: 'Completed',
                  isActive: false,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to scanner for loading/unloading
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan Package'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildDeliveryCard({
    required BuildContext context,
    required String orderId,
    required String customer,
    required String address,
    required int items,
    required ChipStatus status,
    required String statusLabel,
    required String eta,
    required bool isActive,
  }) {
    return IndustrialCard(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing details for $orderId')),
        );
      },
      padding: const EdgeInsets.all(AppDimensions.p16),
      backgroundColor: isActive ? AppColors.accent.withOpacity(0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StatusChip(label: statusLabel, status: status),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    '$items items',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (isActive)
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'ETA: $eta',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          if (isActive) ...[
            const SizedBox(height: AppDimensions.p12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening navigation...')),
                      );
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.p8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marking as delivered...')),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Deliver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
