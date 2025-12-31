import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Widget tablerIconSvg(
  String name, {
  required Color fill,
  required Color stroke,
  double size = 24,
}) {
  return Stack(
    alignment: Alignment.center,
    children: [
      SvgPicture.asset(
        'assets/icons/filled/$name.svg',
        width: size,
        height: size,
        color: fill,
      ),
      SvgPicture.asset(
        'assets/icons/outline/$name.svg',
        width: size,
        height: size,
        color: stroke,
        // colorFilter: ColorFilter.mode(stroke, BlendMode.srcIn),
      ),
    ],
  );
}