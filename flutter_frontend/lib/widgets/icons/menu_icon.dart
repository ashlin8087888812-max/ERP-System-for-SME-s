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

    
    switch(widget.page){
      case AppPage.dashboard:
        return tabler.Menu3();
      case AppPage.sidebar_menu:
        return tabler.ChevronsDown(
          width: 50,height: 50,
        );
      case AppPage.dashboard_sidebar:
        return tabler.ChevronsLeft(
          width: 35,height: 35,
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