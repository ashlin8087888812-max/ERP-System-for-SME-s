import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/adaptive_layout.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/map_function.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/navbar.dart';
import 'package:flutter_frontend/widgets/titles/gestace_title.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, required this.sidebar});

  final bool? sidebar;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with TickerProviderStateMixin{

  @override
  void initState() {
    // TODO: implement initState
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
    final layoutIsLandscape = layoutOrientation == Orientation.landscape && layoutIsMobile;
    const SizedBox spacing  = SizedBox(height: 15);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    bool sidebar = widget.sidebar?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!layoutIsDesktop && sidebar) {
        context.go('/menu');
      }
    });
    Size navbarSize = Size(sidebar? mapWidthScale(300, 600, width):60, 60);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Dashboard'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: () {
      //         ref.read(authProvider.notifier).logout();
      //       },
      //     ),
      //   ],
      // ),
      backgroundColor: palette.white,
      body: AdaptiveLayout(
        child: Stack(
          children: [
            SizedBox(height: height,width: width,),
            // Menu button and Navbar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile? layoutIsPortrait? 14:0:sidebar? 0:8,
              bottom: layoutIsMobile? 0:sidebar? 0:10,
              width: layoutIsPortrait? width-14:navbarSize.width,
              height: layoutIsPortrait? navbarSize.height:height - (sidebar? 0:30),
              child: Flex(
                direction: layoutIsPortrait? Axis.horizontal: Axis.vertical,
                children: [
                  !sidebar?Hero(
                    tag: 'menu_icon',
                    child: HoverIcon(
                      icon: MenuIcon(page: AppPage.dashboard),
                      label: 'Menu',
                      elevate: false,
                      onTap: () {
                        if(layoutIsDesktop){
                          setState(() {
                            sidebar = !sidebar;
                          });
                          sidebar? context.go('/dashboard?sidebar=open'): context.go('/dashboard');
                        } else {
                          context.go('/menu');
                        }
                      },
                    ),
                  ): SizedBox(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: layoutIsPortrait? 0:sidebar? 0:10,left: layoutIsPortrait? 10:0),
                      child: Navbar(
                        size: navbarSize,
                        sidebar: sidebar,
                        page: AppPage.dashboard,
                      )
                    ),
                  )
                ],
              )
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile? layoutIsPortrait? 20:60:80,
              top: layoutIsMobile? layoutIsPortrait? 10:20:25,
              child:!sidebar? Hero(
                tag:'gestace_title',
                child: Material(
                  type: MaterialType.transparency,
                  child: Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.topLeft,
                    child: GestaceTitle(),
                  ),
                ),
              ): SizedBox(),
            ),
            
          ],
        ),
      ),
    );
  }
}
