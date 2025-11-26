import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

class IndustrialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool hasBorder;

  const IndustrialCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        side: hasBorder
            ? BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppDimensions.p16),
          child: child,
        ),
      ),
    );
  }
}
