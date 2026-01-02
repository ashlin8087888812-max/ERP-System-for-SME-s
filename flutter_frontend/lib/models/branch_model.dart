import 'package:flutter/material.dart';

class Branch {
  final String name;
  final String category;
  final Widget icon;
  final Gradient gradient;
  final bool hasImage;
  final String? imageUrl;

  Branch({
    required this.name,
    required this.category,
    required this.icon,
    required this.gradient,
    this.hasImage = false,
    this.imageUrl,
  });
}