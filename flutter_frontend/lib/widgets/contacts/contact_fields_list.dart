import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';

class ContactFieldsList extends StatelessWidget {
  const ContactFieldsList({super.key, required this.layoutIsMobile});

  final bool layoutIsMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4).copyWith(
        left: layoutIsMobile? 12: 4, 
        right: layoutIsMobile? 12: 4),
      decoration: BoxDecoration(
        color: palette.white,
        borderRadius: BorderRadius.circular(16),
        border: layoutIsMobile? Border.all(color: palette.extras[1], width: 1): null,
      ),
    );
  }
}