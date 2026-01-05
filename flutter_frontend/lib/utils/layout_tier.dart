import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// =======================================================
/// Layout tiers based on available screen space
/// (device-agnostic, resize-safe)
/// =======================================================

enum LayoutTier {
  compact,  // phones
  mobile,   // large phones / small tablets
  tablet,   // tablets / small laptops
  desktop,  // large screens
}

/// =======================================================
/// Riverpod provider
/// Emits ONLY when the layout tier actually changes
/// =======================================================

final layoutTierProvider =
    StateNotifierProvider<LayoutTierNotifier, LayoutTier>(
  (ref) => LayoutTierNotifier(),
);

final layoutOrientationProvider =
    StateNotifierProvider<LayoutOrientationNotifier, Orientation>(
  (ref) => LayoutOrientationNotifier(),
);

/// =======================================================
/// Pure function: Size → LayoutTier
/// Safe to reuse anywhere (tests, web, desktop)
/// =======================================================

LayoutTier computeLayoutTier(Size size) {
  final shortest = size.shortestSide;
  if (shortest < 600) return LayoutTier.compact;
  if (shortest < 900) return LayoutTier.mobile;
  if (shortest < 1000) return LayoutTier.tablet;
  return LayoutTier.desktop;
}

/// =======================================================
/// StateNotifier that filters size changes
/// Rebuilds ONLY when tier boundary is crossed
/// =======================================================

class LayoutTierNotifier extends StateNotifier<LayoutTier> {
  LayoutTierNotifier() : super(LayoutTier.compact);

  void updateFromSize(Size size) {
    final next = computeLayoutTier(size);
    
    // Prevent unnecessary rebuilds on every resize
    if (next != state) {
      state = next;
      print(next);
    }
  }
}

class LayoutOrientationNotifier extends StateNotifier<Orientation> {
  LayoutOrientationNotifier() : super(Orientation.portrait);

  void updateFromOrientation(Orientation orientation) {
    if (orientation != state) {
      state = orientation;
      print(orientation);
    }
  }
}
