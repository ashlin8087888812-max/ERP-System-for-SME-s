import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';

class BranchCardA extends StatefulWidget {
  final Branch branch;
  const BranchCardA({super.key, required this.branch});

  @override
  State<BranchCardA> createState() => _BranchCardAState();
}

class _BranchCardAState extends State<BranchCardA> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.branch.gradient,
        borderRadius: BorderRadius.circular(20),
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
          if (widget.branch.hasImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.2),
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
                height: 140,
                margin: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: palette.extras[3],
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(height: 5,),
                    Row(
                      children: [
                        SizedBox(width: 20,),
                        Text(
                          widget.branch.name,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w500,
                            color: palette.black.withOpacity(0.6),
                            letterSpacing: -1.5,
                            fontFamily: 'Lexend',
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DecoratedIcon(
                          iconSvg: message_1,
                          overlaySvg: dots_1,
                          offset: const Offset(13, 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          
        ],
      ),
    );
  }
}