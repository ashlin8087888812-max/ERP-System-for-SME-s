import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/utils/layout_tier.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.of(context).size;

    // Prevent redundant scheduling
    if (_lastSize == size) return;
    _lastSize = size;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(layoutTierProvider.notifier)
          .updateFromSize(size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
