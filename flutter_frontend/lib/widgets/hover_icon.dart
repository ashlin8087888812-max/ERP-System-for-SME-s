import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HoverIcon extends ConsumerStatefulWidget {
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
  ConsumerState<HoverIcon> createState() => _HoverIconState();
}

class _HoverIconState extends ConsumerState<HoverIcon>
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

  void _showOverlay(bool layoutIsPortrait) {
    setState(() {
      _hovering = true;
    });
    if (_entry != null || !widget.elevate) return;

    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: pos.dx +( layoutIsPortrait? -box.size.width: box.size.width/1.2),
        top: pos.dy -( layoutIsPortrait? box.size.height+20: 0),
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
    setState(() {
      _hovering = false;
    });
    if (_entry == null || !widget.elevate) return;

    _controller.reverse().then((_) {
      _entry?.remove();
      _entry = null;
    });
    
  }

  @override
  Widget build(BuildContext context) {
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(layoutIsPortrait),
        onExit: (_) => _hideOverlay(),
        cursor: SystemMouseCursors.click,
        child: Container(
          color: Colors.transparent, // Stable hit-test target
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, (_hovering) ? -4 : 0, 0),
            child: widget.icon,
          ),
        ),
      ),
    );
  }
}
