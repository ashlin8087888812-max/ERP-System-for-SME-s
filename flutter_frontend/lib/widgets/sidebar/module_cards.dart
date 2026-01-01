import 'package:flutter/material.dart';

class ModuleCards extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> colors;     // bottom → top order
  final double spacing;         // horizontal or vertical offset

  const ModuleCards({
    super.key,
    this.width = 150,
    this.height = 200,
    this.spacing = 14,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width + spacing * (colors.length - 1),
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < colors.length; i++)
            Positioned(
              left: i * spacing,
              top: i * spacing,
              child: _Card(
                color: colors[i],
                width: width,
                height: height,
                isTop: i == colors.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final bool isTop;

  const _Card({
    required this.color,
    required this.width,
    required this.height,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular( isTop
            ?22:13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(2, 2),
            blurRadius: 8,
          ),
        ],
        border: isTop
            ? Border.all(color: Colors.grey.shade600, width: 3)
            : null,
      ),
    );
  }
}
