import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/models/contact_model.dart';
import 'package:flutter_frontend/utils/branches.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/map_function.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/contacts/contact_card.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_frontend/widgets/sidebar/branch_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class ContactsBrowser extends ConsumerStatefulWidget {
  final List<ContactModel> contacts;
  const ContactsBrowser({super.key, required this.contacts});

  @override
  ConsumerState<ContactsBrowser> createState() => _ContactsBrowserState();
}

class _ContactsBrowserState extends ConsumerState<ContactsBrowser> {
  String _selectedFilter = 'All';
  String _searchQuery = '';


  List<ContactModel> get _filteredContacts {
    return widget.contacts.where((contact) {
      final matchesSearch = contact.name?.toLowerCase().contains(_searchQuery.toLowerCase());
      // final matchesFilter = _selectedFilter == 'All' || contact.category == _selectedFilter;
      return matchesSearch ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsDesktop = layoutTier == LayoutTier.tablet || layoutTier == LayoutTier.desktop;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        
        // Module Grid
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollBehavior().copyWith(scrollbars: false),
            child: DynMouseScroll(
              scrollSpeed: 1,
              builder: (context, controller, physics) {
                return ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                      ],
                      stops: [0.0, 0.03, 1.0],
                    ).createShader(rect);
                  },
                  child: CustomScrollView(
                    controller: controller,
                    physics: physics,
                    slivers: [
                      // TOP SCROLLING SPACER (replaces your SizedBox)
                      SliverToBoxAdapter(
                        child: SizedBox(height: mapUniformScale(20, 38, width, height)),
                      ),

                      SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ContactCard(
                              contact: _filteredContacts[index],
                            );
                          },
                          childCount: _filteredContacts.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 270,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                      ),

                      // BOTTOM SCROLLING SPACER
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: isSelected ? palette.extras[1] : palette.white,
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = label),
          hoverColor: palette.extras[isSelected ?1:0],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.black : palette.black,
                width: 0.8,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
                letterSpacing: -0.2,
                fontFamily: 'Lexend',
                fontVariations: [
                  FontVariation('wght', 300),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


