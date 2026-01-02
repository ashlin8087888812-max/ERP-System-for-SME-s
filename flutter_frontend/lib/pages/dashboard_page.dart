import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/adaptive_layout.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/animated_icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/dashboard/navbar.dart';
import 'package:flutter_frontend/widgets/gestace_title.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

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

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Dashboard'),
      //   leading: IconButton(
      //     icon: const tabler.Menu3(
            
      //     ),
      //     onPressed: () {
      //       context.push('/menu');
      //     },
      //   ),
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
              
              left: layoutIsMobile? layoutIsPortrait? 14:0:8,
              bottom: layoutIsMobile? 0:10,
              width: layoutIsPortrait? width-14:60,
              height: layoutIsPortrait? 60:height - 30,
              child: Flex(
                direction: layoutIsPortrait? Axis.horizontal: Axis.vertical,
                children: [
                  Hero(
                    tag: 'menu_icon',
                    child: HoverIcon(
                      icon: MenuIcon(page: AppPage.dashboard),
                      label: 'Menu',
                      elevate: false,
                      onTap: () {
                        context.go('/menu');
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only( top: layoutIsPortrait? 0:14,left: layoutIsPortrait? 14:0),
                      child: Navbar()
                    ),
                  )
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile? layoutIsPortrait? 20:60:80,
              top: layoutIsMobile? layoutIsPortrait? 10:20:25,
              child: Hero(
                tag:'gestace_title',
                child: Material(
                  type: MaterialType.transparency,
                  child: Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.topLeft,
                    child: GestaceTitle(),
                  ),
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}
