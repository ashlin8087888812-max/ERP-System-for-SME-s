import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/utils/stripes_painter.dart';
import 'package:flutter_frontend/utils/visibility_observer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;
import '../providers/auth_provider.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?.fullName ?? user?.email ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Stack(
          children: [
            VisibilityObserver(
              child: Opacity(opacity: 0.08, child: StripesBackground(
                color: Colors.black,
                speed: 4.0,
                spacing: 34,
                stripeWidth: 0.5,
              ))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Yours,',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF707070),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'SYNCERELY',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Greetings,',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFF707070),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    userName,
                    style: GoogleFonts.lexend(
                      color: const Color(0xFFECECEC),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'which module would you like to check out?',
                    style: GoogleFonts.lexend(
                      color: const Color(0xFFECECEC),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E3E3E),
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: const Color(0xFF707070), width: 0.4),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF555555),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFF7F7F7F), width: 0.4),
                          ),
                          child: Row(
                            children: [
                              const tabler.Search(color: Color(0xFF1C1C1C), height: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Search',
                                style: GoogleFonts.lexend(
                                  color: const Color(0xFF8B8B8B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const tabler.Pin(color: Color(0xFF1C1C1C), height: 24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildMenuItem(
                              context,
                              iconBuilder: (color) => tabler.AddressBook(color: color, height: 48),
                              label: 'Contacts',
                              isSelected: true,
                              onTap: () => context.push('/contacts'),
                            ),
                            _buildMenuItem(
                              context,
                              iconBuilder: (color) => tabler.MessageCircle(color: color, height: 48),
                              label: 'Discuss',
                              isSelected: false,
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              context,
                              iconBuilder: (color) => tabler.UserCircle(color: color, height: 48),
                              label: 'Profiles',
                              isSelected: false,
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              context,
                              iconBuilder: (color) => tabler.Settings(color: color, height: 48),
                              label: 'Settings',
                              isSelected: false,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required Widget Function(Color) iconBuilder,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isSelected ? Colors.white : const Color(0xFF555555);
    final foregroundColor = isSelected ? Colors.black : const Color(0xFF8B8B8B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          hoverColor: isSelected ? backgroundColor: const Color(0xFF3E3E3E),
          splashColor: isSelected ? backgroundColor: palette.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFF7F7F7F), width: 0.4),
            ),
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                 Align(
                  alignment: Alignment.topRight,
                  child: iconBuilder(foregroundColor),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    style: GoogleFonts.lexend(
                      color: foregroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
