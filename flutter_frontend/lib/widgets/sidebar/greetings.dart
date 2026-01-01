import 'package:flutter/material.dart';

class GreetingWidget extends StatelessWidget {
  final String name;

  const GreetingWidget({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Greetings,",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            fontFamily: "Screen",
            height: 1.3,
          ),
        ),

        Text(
          name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            fontFamily: "Raster",        // same pixel font as screenshot
            height: 1.1,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "which branch would you like to check out?",
          style: TextStyle(
            fontSize: 20,
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
