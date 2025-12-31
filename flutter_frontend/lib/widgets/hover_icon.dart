import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class HoverIcon extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Widget icon;
  final bool elevate;

  const HoverIcon({
    required this.label,
    required this.onTap,
    required this.icon,
    this.elevate = true,
    super.key,
  });

  @override
  State<HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _offset = Tween(begin: const Offset(0, 0.0), end: const Offset(0.5, -0.0))
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _entry?.remove();
    super.dispose();
  }

  void _showOverlay() {
    if (_entry != null || !widget.elevate) return;

    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    setState(() {
      _hovering = true;
    });
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx + box.size.width/1.2,
        top: pos.dy,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _offset,
                child: Container(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: palette.black,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lexend'
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);
    _controller.forward(); 
  }

  void _hideOverlay() {
    
    if (_entry == null || !widget.elevate) return;

    _controller.reverse().then((_) {
      _entry?.remove();
      _entry = null;
    });
    setState(() {
      _hovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showOverlay(),
      onExit: (_) => _hideOverlay(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, (_hovering && widget.elevate) ? -4 : 0, 0),
          child: widget.icon,
        ),
      ),
    );
  }
}
