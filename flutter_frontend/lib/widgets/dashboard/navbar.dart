import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/pages/sidebar_menu.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/utils/sized_box_ops.dart';
import 'package:flutter_frontend/utils/stripes_painter.dart';
import 'package:flutter_frontend/utils/tabler_icon.dart';
import 'package:flutter_frontend/utils/visibility_observer.dart';
import 'package:flutter_frontend/widgets/titles/gestace_title.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:flutter_frontend/widgets/icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/sidebar/branch_browser.dart';
import 'package:flutter_frontend/widgets/sidebar/greetings.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;


class Navbar extends ConsumerWidget {
  final bool isPotrait;
  final Size size;
  final bool sidebar;
  final AppPage page;
  const Navbar({
    super.key,
    this.isPotrait = false,
    required this.size,
    this.sidebar = false,
    required this.page,
  });
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const SizedBox spacing  = SizedBox(height: 15,width: 15,);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsDesktop = layoutTier == LayoutTier.tablet || layoutTier == LayoutTier.desktop;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    final layoutIsLandscape = layoutOrientation == Orientation.landscape && layoutIsMobile;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    Widget divider =  layoutIsPortrait?
    VerticalDivider(indent: 15,endIndent: 15,color: palette.black.withOpacity(0.2), thickness: 0.3,):
    Divider(indent: 15,endIndent: 15,color: palette.black.withOpacity(0.2), thickness: 0.8,);

    Widget navbar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(sidebar? 0:20))
            .copyWith(
              topRight:Radius.circular(layoutIsPortrait? 20:sidebar? 0:120),
              topLeft:Radius.circular(layoutIsPortrait? 120:sidebar? 0:20),),
        boxShadow: [
          BoxShadow(
            color: palette.black.withOpacity(sidebar? 0.03:0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(layoutIsMobile?0:sidebar? 0:20))
            .copyWith(
              topRight:Radius.circular(layoutIsPortrait? 0:sidebar? 0:120),
              topLeft:Radius.circular(layoutIsPortrait? 120:layoutIsMobile?0:sidebar? 0:20),
              ),
        child: InnerShadow(
          shadows: [
           if(layoutIsLandscape)  Shadow(
              color: palette.black.withOpacity(0.04),
              offset: const Offset(-2, -2),
              blurRadius: 0,
            ),
            Shadow(
              color: palette.white.withOpacity(0.3),
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width:layoutIsPortrait? width: size.width,
                height: layoutIsPortrait? size.height :height,
                decoration: BoxDecoration(
                  color: palette.extras[0].withOpacity(sidebar? 0:1),
                  borderRadius: BorderRadius.all(Radius.circular(layoutIsMobile?0:sidebar? 0:20))
                .copyWith(
                  topRight:Radius.circular(layoutIsPortrait? 0:sidebar? 0:120),
                  topLeft:Radius.circular(layoutIsPortrait? 120:layoutIsMobile?0:sidebar? 0:20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 5),
              
                child: Flex(
                  direction: layoutIsPortrait ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      child: DynMouseScroll(
                        scrollSpeed: 1,
                        builder: (context, controller, physics) {
                          return SingleChildScrollView(
                            controller: controller,
                            physics: physics,
                            child: Flex(
                              direction: layoutIsPortrait ? Axis.horizontal : Axis.vertical,
                              mainAxisAlignment:layoutIsMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
                              children: [
                                const SizedBox(height: 50),
                                HoverIcon(
                                  label: 'Dashboard',
                                  icon: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: SvgPicture.asset(
                                      'assets/icons/dashboard_2.svg',
                                      color: palette.extras[1],
                                    ),
                                  ),
                                  onTap: () => context.go('/dashboard'),
                                  elevate: page != AppPage.dashboard,
                                ),

                                spacing,
                                
                                HoverIcon(
                                  label: 'Contacts',
                                  icon: tabler.UserFilled(color:palette.extras[1]),
                                  onTap: () => context.go('/contacts'),
                                  elevate: page != AppPage.contacts,
                                ),
                            
                                spacing,
                            
                                HoverIcon(
                                  label: 'Threads',
                                  icon: tabler.MessageFilled(color: palette.extras[1]),
                                  onTap: () => context.go('/threads'),
                                  elevate: page != AppPage.threads,
                                ),
                            
                                spacing,
                            
                                HoverIcon(
                                  label: 'Profiles',
                                  icon: tabler.CategoryFilled(color: palette.extras[1],),
                                  onTap: () => context.go('/profiles'),
                                  elevate: page != AppPage.profiles,
                                ),
                                spacing,
                            
                                HoverIcon(
                                  label: 'Settings',
                                  icon: tabler.SettingsFilled(color: palette.extras[1],),
                                  onTap: () => context.go('/settings'),
                                  elevate: page != AppPage.settings,
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                    divider,
                    spacing-5,
                    HoverIcon(
                      label: 'Settings',
                      elevate: layoutIsPortrait? false:true,
                      icon: tabler.SettingsFilled(color: palette.extras[1],),
                      onTap: () => context.go('/settings'),
                    ),
                    spacing-5,
                  
                  ],
                ),
              ),
              // Desktop mode Sidebar
              AnimatedOpacity(
                opacity: sidebar? 1:0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !sidebar,
                  child: Stack(
                    children: [
                      DecoratedBox(decoration: BoxDecoration(
                        color: palette.extras[3],
                      ),
                      child: SizedBox(
                        width:layoutIsPortrait? width: size.width,
                        height: layoutIsPortrait? size.height :height,
                      ),
                      ),
                      VisibilityObserver(
                      child: Opacity(
                        opacity: 0.1, 
                        child: StripesBackground(
                        color: Colors.black,
                        speed: 4.0,
                        spacing: 90,
                        stripeWidth: 0.5,
                      ))),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        top: 20,
                        left: 20,
                        width:layoutIsPortrait? width-40: size.width-40,
                        height: layoutIsPortrait? size.height -40:height-40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestaceTitle(),
                                  spacing*5,
                                  FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: GreetingWidget(
                                      name: user?.fullName ?? user?.email ?? 'User',
                                      size: 28,
                                      ))
                                ],
                              ),
                            ),
                            spacing,
                            sidebar? Expanded(child: BranchBrowser()): SizedBox(),
                          ],
                        )),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        top: 20,
                        right: 20,
                        child: sidebar? Hero(
                          tag: 'menu_icon',
                          child: HoverIcon(
                            icon: Opacity( 
                              opacity: 0.5,
                              child: MenuIcon(page: AppPage.dashboard_sidebar)
                            ),
                            label: 'Menu',
                            elevate: false,
                            onTap: () {
                              context.go('/dashboard');
                            },
                          ),
                        ) : SizedBox(),
                      ),
                      
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
    

    return sidebar? navbar: Hero(
      tag: 'navbar',
      child: navbar,
    );
  }
}


