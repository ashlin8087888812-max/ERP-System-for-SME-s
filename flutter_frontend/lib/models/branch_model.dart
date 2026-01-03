import 'package:flutter/material.dart';

class Branch {
  final String name;
  final String category;
  final Widget icon;
  final Gradient gradient;
  final bool hasImage;
  final String? imageUrl;
  final Function(String color, String strokeWidth, String strokeColor) iconSvg;
  final Function(String color, String strokeWidth, String strokeColor) overlaySvg;
  final double iconSize;
  final double overlaySize;
  final Offset offset;
  final bool showOverlay;
  final bool showIcon;
  final Color color;
  final String url;

  Branch({
    required this.name,
    required this.category,
    required this.icon,
    required this.gradient,
    this.hasImage = false,
    this.imageUrl,
    required this.iconSvg,
    required this.overlaySvg,
    required this.iconSize,
    required this.overlaySize,
    required this.offset,
    this.showOverlay = true,
    this.showIcon = true,
    required this.color,
    required this.url,
  });
}