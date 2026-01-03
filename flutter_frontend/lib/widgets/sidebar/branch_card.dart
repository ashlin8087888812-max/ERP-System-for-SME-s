import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

class BranchCard extends StatefulWidget {
  final bool isA;
  final Branch branch;
  const BranchCard({
    super.key, 
    required this.branch, 
    required this.isA,
  });
  

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard> {
  @override
  void didUpdateWidget(covariant BranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch.iconSize != widget.branch.iconSize || oldWidget.branch.overlaySize != widget.branch.overlaySize) {
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {

    if (widget.isA) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
          decoration: BoxDecoration(
            color: widget.branch.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background image if available
              Positioned.fill(
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              
              Positioned(
                bottom: 0,
                width: constraints.maxWidth,
                child: InnerShadow(
                  shadows: [
                    Shadow(
                      color: palette.black.withOpacity(0.08),
                      offset: const Offset(-3, -3),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: palette.white.withOpacity(0.3),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                    ],
                  child: Container(
                    height: constraints.maxHeight/1.6,
                    margin: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: palette.extras[3],
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 3,
                          spreadRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5,),
                        Row(
                          children: [
                            SizedBox(width: 20,),
                            SizedBox(
                              width: constraints.maxWidth/2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.branch.name,
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w400,
                                    color: palette.black.withOpacity(0.6),
                                    letterSpacing: -3,
                                    fontFamily: 'Lexend',
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(child: SizedBox(height: 5,)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DecoratedIcon(
                              iconSvg: widget.branch.iconSvg,
                              overlaySvg: widget.branch.overlaySvg,
                              iconSize: (widget.branch.iconSize-(constraints.maxHeight/55)).clamp(0, widget.branch.iconSize),
                              overlaySize: widget.branch.overlaySize,
                              offset: widget.branch.offset,
                              showOverlay: widget.branch.showOverlay,
                              showIcon: widget.branch.showIcon,
                            ),
                            SizedBox(width: 15,),
                          ],
                        ),
                        SizedBox(height: 15,),
                      ],
                    ),
                  ),
                ),
              ),
              
              
            ],
          ),
              );
        }
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                margin: EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: widget.branch.color,
                  borderRadius: BorderRadius.circular(15).copyWith(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),),
              // Background image if available
              Positioned.fill(
                  child: Container(
                    margin: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),
              
              Positioned(
                child: InnerShadow(
                  shadows: [
                    Shadow(
                      color: palette.black.withOpacity(0.08),
                      offset: const Offset(-3, -3),
                      blurRadius: 0,
                    ),
                    Shadow(
                      color: palette.white.withOpacity(0.3),
                      offset: const Offset(3, 3),
                      blurRadius: 0,
                    ),
                    ],
                  child: Container(
                    height: constraints.maxHeight/1.6,
                    margin: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: palette.extras[3],
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          spreadRadius: 3,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5,),
                        Row(
                          children: [
                            SizedBox(width: 20,),
                            SizedBox(
                              width: constraints.maxWidth/2,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.branch.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w400,
                                    color: palette.black.withOpacity(0.6),
                                    letterSpacing: -3,
                                    fontFamily: 'Lexend',
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(child: SizedBox(height: 5,)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DecoratedIcon(
                              iconSvg: widget.branch.iconSvg,
                              overlaySvg: widget.branch.overlaySvg,
                              iconSize: (widget.branch.iconSize-(constraints.maxHeight/55)).clamp(0, widget.branch.iconSize),
                              overlaySize: (widget.branch.overlaySize-(constraints.maxHeight/55)).clamp(0, widget.branch.overlaySize),
                              offset: widget.branch.offset,
                              showOverlay: widget.branch.showOverlay,
                              showIcon: widget.branch.showIcon,
                            ),
                            SizedBox(width: 15,),
                          ],
                        ),
                        SizedBox(height: 15,),
                      ],
                    ),
                  ),
                ),
              ),
              
              
            ],
          );
        }
      );
    }
  }
}