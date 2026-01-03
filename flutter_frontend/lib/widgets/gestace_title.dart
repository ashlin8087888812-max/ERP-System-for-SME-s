import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';

class GestaceTitle extends StatelessWidget {
  final double fontSize;

  const GestaceTitle({
    this.fontSize = 62,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color color = palette.black;
    return RichText(
      text: TextSpan(
        children: [

          /// "Ges"
          TextSpan(
            text: "Ges",
            style: TextStyle(
              fontFamily: "Lexend",
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: -3,
            ),
          ),
          /// "t"
          TextSpan(
            text: "t",
            style: TextStyle(
              fontFamily: "Lexend",
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: -6,
            ),
          ),

          /// "ace" + tagline
          WidgetSpan(
            style: TextStyle(letterSpacing: -50),
            baseline: TextBaseline.alphabetic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // tagline
                Text(
                  "For All Time. Always. ",
                  style: TextStyle(
                    fontFamily: "Lexend",
                    fontSize: 9.5, 
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.5),
                    height: 0.9,
                    letterSpacing: -0.1,
                  ),
                ),

                Text(
                  "ace",
                  style: TextStyle(
                    fontFamily: "Raster",
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    color: color,
                     height: 0.6
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
