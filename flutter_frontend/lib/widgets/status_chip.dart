import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

enum ChipStatus { success, warning, error, info, neutral }

class StatusChip extends StatelessWidget {
  final String label;
  final ChipStatus status;

  const StatusChip({
    super.key,
    required this.label,
    this.status = ChipStatus.neutral,
  });

  Color _getColor() {
    switch (status) {
      case ChipStatus.success:
        return AppColors.success;
      case ChipStatus.warning:
        return AppColors.warning;
      case ChipStatus.error:
        return AppColors.error;
      case ChipStatus.info:
        return AppColors.info;
      case ChipStatus.neutral:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.p8, vertical: AppDimensions.p4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.r4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ).copyWith(
          color: color,
        ),
      ),
    );
  }
}
