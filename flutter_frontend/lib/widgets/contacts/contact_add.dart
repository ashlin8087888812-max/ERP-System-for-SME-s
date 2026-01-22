import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class ContactAdd extends StatelessWidget {
  ContactAdd({super.key});

  // Local UI-only state (no need for StatefulWidget)
  final ValueNotifier<bool> _isPerson = ValueNotifier(true);

  // Cache icons so they don't rebuild unnecessarily
  late final Widget _personIcon = SvgPicture.asset(
    'assets/icons/person.svg',
    width: 40,
    height: 40,
    colorFilter: ColorFilter.mode(
      palette.extras[1],
      BlendMode.srcIn,
    ),
  );

  late final Widget _companyIcon = SvgPicture.asset(
    'assets/icons/shop.svg',
    width: 40,
    height: 40,
    colorFilter: ColorFilter.mode(
      palette.extras[1],
      BlendMode.srcIn,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        color: palette.extras[0],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 10),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isPerson,
        builder: (context, isPerson, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPerson
                    ? " Add New Person's\n Contact."
                    : " Add New Company's\n Contact.",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.extras[1],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Lexend',
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),

              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/contacts/new'),
                    child: tabler.Plus(
                      width: 90,
                      height: 90,
                      strokeWidth: 2.5,
                      color: palette.extras[2],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Center(
                child: Container(
                  height: 100,
                  width: 180,
                  decoration: BoxDecoration(
                    color: palette.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _isPerson.value = true,
                          child: _SelectTile(
                            active: isPerson,
                            child: _personIcon,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _isPerson.value = false,
                          child: _SelectTile(
                            active: !isPerson,
                            child: _companyIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? palette.extras[0] : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(child: child),
    );
  }
}

class ContactAddMini extends StatelessWidget {
  const ContactAddMini({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: palette.extras[1],
        child: InkWell(
          onTap: () => context.go('/contacts/new'),
          hoverColor: palette.white.withOpacity(0.1),
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(bottom: 5, left: 8, right: 8, top: 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    " New\n Contact",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Lexend',
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                tabler.Plus(
                  width: 40,
                  height: 40,
                  strokeWidth: 2.5,
                  color: palette.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
