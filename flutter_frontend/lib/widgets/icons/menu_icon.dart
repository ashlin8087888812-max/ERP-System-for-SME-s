import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class MenuIcon extends ConsumerStatefulWidget {
  final AppPage page;
  const MenuIcon({super.key, required this.page});

  @override
  ConsumerState<MenuIcon> createState() => _MenuIconState();
}

class _MenuIconState extends ConsumerState<MenuIcon> with TickerProviderStateMixin {
  late final AnimationController menuAnimationController;
  

  @override
  void initState() {
    menuAnimationController = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    menuAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsDesktop = layoutTier == LayoutTier.tablet || layoutTier == LayoutTier.desktop;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    final layoutIsLandscape = layoutOrientation == Orientation.landscape && layoutIsMobile;
    const SizedBox spacing  = SizedBox(height: 15);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    
    switch(widget.page){
      case AppPage.dashboard:
        return tabler.Menu3();
      case AppPage.sidebar_menu:
        return tabler.ChevronsDown(
          width: 50,height: 50,
        );
      default:
        return kIsWeb? tabler.Menu3(): Lottie.asset(
        'assets/anims/menu_to_chevron_down.json',
        height: 30,
        width: 30,
        fit: BoxFit.contain,
        repeat: false,
        controller: menuAnimationController,
        onLoaded: (composition) {
          menuAnimationController
            ..duration = composition.duration..forward()
            ..reverse();
        },
      );
    }
    
  }
}