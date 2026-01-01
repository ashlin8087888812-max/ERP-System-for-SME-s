import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/utils/sized_box_ops.dart';
import 'package:flutter_frontend/utils/tabler_icon.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;


class Navbar extends ConsumerWidget {
  final bool isPotrait;
  const Navbar({
    super.key,
    this.isPotrait = false,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const SizedBox spacing  = SizedBox(height: 15,width: 15,);
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
    

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20))
            .copyWith(
              topRight:Radius.circular(layoutIsPortrait? 20:120),
              topLeft:Radius.circular(layoutIsPortrait? 120:20),),
        boxShadow: [
          BoxShadow(
            color: palette.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(layoutIsMobile?0:20))
            .copyWith(
              topRight:Radius.circular(layoutIsPortrait? 0:120),
              topLeft:Radius.circular(layoutIsPortrait? 120:layoutIsMobile?0:20),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:layoutIsPortrait? width: 60,
            height: layoutIsPortrait?60:height,
            decoration: BoxDecoration(
              color: palette.extras[0],
              borderRadius: BorderRadius.all(Radius.circular(layoutIsMobile?0:20))
            .copyWith(
              topRight:Radius.circular(layoutIsPortrait? 0:120),
              topLeft:Radius.circular(layoutIsPortrait? 120:layoutIsMobile?0:20),
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
                              label: 'Contacts',
                              icon: tabler.UserFilled(color:palette.extras[1]),
                              onTap: () => context.go('/contacts'),
                            ),
                        
                            spacing,
                        
                            HoverIcon(
                              label: 'Threads',
                              icon: tabler.MessageFilled(color: palette.extras[1]),
                              onTap: () => context.go('/threads'),
                            ),
                        
                            spacing,
                        
                            HoverIcon(
                              label: 'Profiles',
                              icon: tabler.CategoryFilled(color: palette.extras[1],),
                              onTap: () => context.go('/profiles'),
                            ),
                            spacing,
                        
                            HoverIcon(
                              label: 'Settings',
                              icon: tabler.SettingsFilled(color: palette.extras[1],),
                              onTap: () => context.go('/settings'),
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
        ),
      ),
    );
  }
}


