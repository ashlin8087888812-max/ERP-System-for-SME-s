import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../widgets/industrial_card.dart';

class StockInventoryPage extends StatelessWidget {
  const StockInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.p16),
        children: [
          _buildStockCard(
            itemCode: 'ITEM-001',
            name: 'Steel Rods 12mm',
            category: 'Raw Materials',
            currentStock: 850,
            minStock: 500,
            unit: 'pcs',
            location: 'Warehouse A - Rack 12',
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildStockCard(
            itemCode: 'ITEM-002',
            name: 'Aluminum Sheets',
            category: 'Raw Materials',
            currentStock: 320,
            minStock: 400,
            unit: 'pcs',
            location: 'Warehouse A - Rack 15',
            isLowStock: true,
          ),
          const SizedBox(height: AppDimensions.p12),
          _buildStockCard(
            itemCode: 'ITEM-003',
            name: 'Finished Product A',
            category: 'Finished Goods',
            currentStock: 145,
            minStock: 100,
            unit: 'units',
            location: 'Warehouse B - Section 3',
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard({
    required String itemCode,
    required String name,
    required String category,
    required int currentStock,
    required int minStock,
    required String unit,
    required String location,
    bool isLowStock = false,
  }) {
    final stockPercentage = (currentStock / minStock).clamp(0.0, 1.0);
    final stockColor = isLowStock ? AppColors.error : AppColors.success;

    return IndustrialCard(
      onTap: () {},
      padding: const EdgeInsets.all(AppDimensions.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemCode,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.p8,
                    vertical: AppDimensions.p4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.r4),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'LOW STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.p8),
          Text(
            category,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppDimensions.p12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Stock',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$currentStock $unit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Min Stock',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$minStock $unit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.p12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r4),
            child: LinearProgressIndicator(
              value: stockPercentage,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(stockColor),
            ),
          ),
        ],
      ),
    );
  }
}
