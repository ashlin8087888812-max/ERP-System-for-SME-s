import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/adaptive_layout.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/utils/sized_box_ops.dart';
import 'package:flutter_frontend/utils/stripes_painter.dart';
import 'package:flutter_frontend/utils/visibility_observer.dart';
import 'package:flutter_frontend/widgets/icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/titles/gestace_title.dart';
import 'package:flutter_frontend/widgets/branch_browser/branch_browser.dart';
import 'package:flutter_frontend/widgets/branch_browser/greetings.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:flutter_frontend/widgets/branch_browser/module_carousel_cards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class BranchBrowserMenu extends ConsumerStatefulWidget {
  const BranchBrowserMenu({super.key});

  @override
  ConsumerState<BranchBrowserMenu> createState() => _BranchBrowserMenuState();
}

class _BranchBrowserMenuState extends ConsumerState<BranchBrowserMenu> with TickerProviderStateMixin {
  

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsDesktop = layoutTier == LayoutTier.tablet || layoutTier == LayoutTier.desktop;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    const SizedBox spacing  = SizedBox(height: 15,width: 15,);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (layoutIsDesktop) {
      context.go('/dashboard?sidebar=open');
    }
  });

    return Scaffold(
      backgroundColor: palette.white,
      body: AdaptiveLayout(
        child: SafeArea(
          child: Stack(
            children: [
              VisibilityObserver(
                child: Opacity(opacity: 0.08, child: StripesBackground(
                  color: Colors.black,
                  speed: 4.0,
                  spacing: 90,
                  stripeWidth: 0.5,
                ))),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top:45,
                left:layoutIsPortrait ?30:45,
                child:Hero(tag:'gestace_title',child: Material(
                  type: MaterialType.transparency,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: layoutIsPortrait ? 1.2 : 1.3,
                    alignment: Alignment.topLeft,
                    child: GestaceTitle())))),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: layoutIsPortrait ?85:null,
                bottom:layoutIsPortrait ?null:45,
                left:layoutIsPortrait ?null:45,
                right:layoutIsPortrait ?20:null,
                width:layoutIsPortrait ? width: width/2.25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Hero(
                      tag: 'menu_icon',
                      child: HoverIcon(
                        icon: Opacity( 
                          opacity: 0.5,
                          child: MenuIcon(page: AppPage.sidebar_menu)
                        ),
                        label: 'Menu',
                        elevate: false,
                        onTap: () {
                          context.go('/dashboard');
                        },
                      ),
                    ),
                    ModuleCarouselCards(
                      colors: [
                        palette.tertiary,
                        palette.secondary,
                        palette.primary,
                      ],
                      spacing:layoutIsPortrait? 12: 14,
                      width:layoutIsPortrait? 120: 150,
                      height:layoutIsPortrait?160: 200,
                    ),
                    spacing*(layoutIsPortrait? 0.5:6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if(layoutIsPortrait )spacing+5+30,
                        Expanded(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: layoutIsPortrait ? 0.8 : 1,
                            alignment: Alignment.topLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: GreetingWidget(
                                name: user?.fullName ?? user?.email ?? 'User',
                                size: 32,
                                ))),
                        ),
                      ],
                    ),
                  ],
                )
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top:layoutIsPortrait ?390:45,
                  right:layoutIsPortrait ?15:45,
                  width:layoutIsPortrait ? width-30: width/2.4,
                  height: layoutIsPortrait ? height-380: height-45,
                  child: BranchBrowser())
            ],
          ),
        ),
      ),
    );
  }

}
