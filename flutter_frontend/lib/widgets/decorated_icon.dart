import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DecoratedIcon extends ConsumerStatefulWidget {
  final Function(String color, String strokeWidth, String strokeColor) iconSvg;
  final Function(String color, String strokeWidth, String strokeColor) overlaySvg;
  final Offset offset;
  const DecoratedIcon({super.key, required this.iconSvg, required this.offset, required this.overlaySvg});

  @override
  ConsumerState<DecoratedIcon> createState() => _DecoratedIconState();
}

class _DecoratedIconState extends ConsumerState<DecoratedIcon> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: 90,
        ),
        Positioned(
          left: 20,
          child: SvgPicture.string(
            message_1(palette.extras[2].hexRGB, "0.0", palette.extras[0].hexRGB),
            width: 65,
            allowDrawingOutsideViewBox: true,
          ),
        ),
        Positioned(
          right: widget.offset.dx+2,
          top: widget.offset.dy,
          child: SvgPicture.string(widget.overlaySvg(palette.extras[1].hexRGB, "0.5", palette.extras[1].hexRGB),
            width: 40,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.extras[1].withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: -8,
                offset: Offset(0,0),
              ),
            ],
          ),
          child: SvgPicture.string(widget.iconSvg(palette.extras[1].hexRGB, "0.0", palette.extras[0].hexRGB),
            width: 65,
          ),
        ),
        Positioned(
          left: widget.offset.dx,
          top: widget.offset.dy,
          child: SvgPicture.string(widget.overlaySvg(palette.white.hexRGB, "0.5", palette.white.hexRGB),
            width: 40,
          ),
        ),
      ],
    );
  }
}