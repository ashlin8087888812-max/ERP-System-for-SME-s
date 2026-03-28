import 'package:flutter/material.dart';

class GreetingWidget extends StatelessWidget {
  final String name;
  final double size;

  const GreetingWidget({
    super.key,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Greetings,",
          style: TextStyle(
            fontSize: size-12,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            fontFamily: "Screen",
            height: 1.3,
          ),
        ),

        Text(
          name,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w400,
            fontFamily: "Raster",        // same pixel font as screenshot
            height: 1.1,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "which branch would you like to check out?",
          style: TextStyle(
            fontSize: size-12,
            fontWeight: FontWeight.w400,
            color: Colors.black.withOpacity(0.65),
            letterSpacing: -1,
            height: 1.3,
            fontFamily: "Lexend"
          ),
        ),
      ],
    );
  }
}
