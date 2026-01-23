import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// =======================================================
/// Root-level listener
/// Feeds MediaQuery size into Riverpod ONCE per build
/// =======================================================

class AdaptiveLayout extends ConsumerStatefulWidget {
  const AdaptiveLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AdaptiveLayout> createState() =>
      _AdaptiveLayoutState();
}

class _AdaptiveLayoutState extends ConsumerState<AdaptiveLayout> {

  Size? _lastSize;
  Orientation? _lastOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // Prevent redundant scheduling
    if (_lastSize == size && _lastOrientation == orientation) return;
    _lastSize = size;
    _lastOrientation = orientation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(layoutTierProvider.notifier)
          .updateFromSize(size);
      ref
          .read(layoutOrientationProvider.notifier)
          .updateFromOrientation(orientation);
          // print('AdaptiveLayout: $size, $orientation');
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
