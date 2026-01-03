import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DecoratedIcon extends ConsumerStatefulWidget {
  final Function(String color, String strokeWidth, String strokeColor) iconSvg;
  final Function(String color, String strokeWidth, String strokeColor) overlaySvg;
  final double iconSize;
  final double overlaySize;
  final Offset offset;
  final bool showOverlay;
  final bool showIcon;
  const DecoratedIcon({super.key, required this.iconSvg, required this.offset, required this.overlaySvg, required this.iconSize, required this.overlaySize, this.showOverlay = true, this.showIcon = true});

  @override
  ConsumerState<DecoratedIcon> createState() => _DecoratedIconState();
}

class _DecoratedIconState extends ConsumerState<DecoratedIcon> {
  @override
  void didUpdateWidget(covariant DecoratedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconSize != widget.iconSize || oldWidget.overlaySize != widget.overlaySize) {
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.iconSize; 
    final double overlaySize = widget.overlaySize;
    return Stack(
      children: [
        SizedBox(
          width: iconSize+22,
        ),
        if(!widget.showOverlay) Positioned(
          left: 22,
          top: 6,
          child: Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.extras[1], 
          ),
            width: iconSize-5, 
            height: iconSize-10,)
          ),
        
        Positioned(
          left: 20,
          child: SvgPicture.string(
            widget.iconSvg(palette.extras[2].hexRGB, "0.0", palette.extras[0].hexRGB),
            width: iconSize,
            allowDrawingOutsideViewBox: true,
          ),
        ),
        if(widget.showOverlay) Positioned(
          right: widget.offset.dx-8,
          top: widget.offset.dy,
          child: SvgPicture.string(widget.overlaySvg(palette.extras[1].hexRGB, "0.4", palette.extras[1].hexRGB),
            width: overlaySize,
          ),
        ),
        if(!widget.showOverlay) Positioned(
          left: 2,
          top: 5,
          child: Container(
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.white,
            boxShadow: [
              
              // BoxShadow(
              //   color: palette.extras[1].withOpacity(0.2),
              //   blurRadius: 2,
              //   spreadRadius: 8,
              //   offset: Offset(2,0),
              // ),
            ],
          ),
            width: iconSize-5, 
            height: iconSize-10,)
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // if(widget.showOverlay)
              // BoxShadow(
              //   color: palette.extras[1].withOpacity(0.3),
              //   blurRadius: 5,
              //   spreadRadius: -8,
              //   offset: Offset(0,0),
              // ),
            ],
          ),
          child: SvgPicture.string(widget.iconSvg(palette.extras[1].hexRGB, "0.0", palette.extras[0].hexRGB),
            width: iconSize,
          ),
        ),
        if(widget.showOverlay) Positioned(
          left: widget.offset.dx,
          top: widget.offset.dy,
          child: SvgPicture.string(widget.overlaySvg(palette.white.hexRGB, "0.4", palette.white.hexRGB),
            width: overlaySize,
          ),
        ),
      ],
    );
  }
}