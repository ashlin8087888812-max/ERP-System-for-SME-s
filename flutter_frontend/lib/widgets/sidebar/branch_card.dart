import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

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

  bool _isHovered = false;


  @override
  void didUpdateWidget(covariant BranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch.iconSize != widget.branch.iconSize || oldWidget.branch.overlaySize != widget.branch.overlaySize) {
      setState(() {});
    }
  }
  @override
  Widget build(BuildContext context) {

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          context.go(widget.branch.url);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (widget.isA) {
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
              
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _isHovered ? (constraints.maxHeight- (constraints.maxHeight/1.42)).clamp(5, constraints.maxHeight): 0,
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
                              width: (constraints.maxWidth-55).clamp(5, constraints.maxWidth),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
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
                            SizedBox(width: 20,),
                          ],
                        ),
                        Expanded(child: SizedBox(height: 5,)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedSlide(
                                offset: _isHovered ? Offset(-0.1, 0.1) : Offset(-2, 0),
                                duration: const Duration(milliseconds: 300),
                                child: tabler.ChevronsUpRight(
                                  color: palette.extras[1].withOpacity(0.2),
                                  height: (widget.branch.iconSize-(constraints.maxHeight/55)).clamp(0, widget.branch.iconSize),),
                              ),
                              DecoratedIcon(
                                iconSvg: widget.branch.iconSvg,
                                overlaySvg: widget.branch.overlaySvg,
                                iconSize: (widget.branch.iconSize-(constraints.maxHeight/55)).clamp(0, widget.branch.iconSize),
                                overlaySize: widget.branch.overlaySize,
                                offset: widget.branch.offset,
                                showOverlay: widget.branch.showOverlay,
                                showIcon: widget.branch.showIcon,
                              ),
                              // SizedBox(width: 15,),
                            ],
                          ),
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
            } else {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.branch.color,
                      borderRadius: BorderRadius.circular(15).copyWith(
                        topLeft: _isHovered ? Radius.circular(15) : Radius.circular(35),
                        topRight: _isHovered ? Radius.circular(15) : Radius.circular(35),
                        bottomLeft: _isHovered ? Radius.circular(35) : Radius.circular(15),
                        bottomRight: _isHovered ? Radius.circular(35) : Radius.circular(15),
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
                  
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: _isHovered ? (constraints.maxHeight- (constraints.maxHeight/1.5)).clamp(5, constraints.maxHeight): 0,
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: constraints.maxHeight/1.6,
                        margin: EdgeInsets.all(5),
                        width: (constraints.maxWidth-10).clamp(5, constraints.maxWidth),
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
                                  width: (constraints.maxWidth-45).clamp(5, constraints.maxWidth),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
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
                                SizedBox(width: 10,),
                              ],
                            ),
                            Expanded(child: SizedBox(height: 5,)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AnimatedSlide(
                                    offset: _isHovered ? Offset(-0.1, 0.2) : Offset(-2, 0),
                                    duration: const Duration(milliseconds: 300),
                                    child: tabler.ChevronsUpRight(
                                      color: palette.extras[1].withOpacity(0.2),
                                      height: 50,
                                  ),
                                  ),
                                  DecoratedIcon(
                                    iconSvg: widget.branch.iconSvg,
                                    overlaySvg: widget.branch.overlaySvg,
                                    iconSize: (widget.branch.iconSize-(constraints.maxHeight/55)).clamp(0, widget.branch.iconSize),
                                    overlaySize: (widget.branch.overlaySize-(constraints.maxHeight/55)).clamp(0, widget.branch.overlaySize),
                                    offset: widget.branch.offset,
                                    showOverlay: widget.branch.showOverlay,
                                    showIcon: widget.branch.showIcon,
                                  ),
                                  // SizedBox(width: 15,),
                                ],
                              ),
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
          },
        ),
      ),
    );

    
  }
}