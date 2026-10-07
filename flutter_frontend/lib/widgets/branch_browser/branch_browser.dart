import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/utils/branches.dart';
import 'package:flutter_frontend/utils/map_function.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/branch_browser/branch_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class BranchBrowser extends ConsumerStatefulWidget {
  const BranchBrowser({super.key});

  @override
  ConsumerState<BranchBrowser> createState() => _BranchBrowserState();
}

class _BranchBrowserState extends ConsumerState<BranchBrowser> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  List<Branch> get _modules => [
    contacts,
    threads,
    settings,
    profiles,
    sales,
    accounting,
    inventory,
  ];

  List<Branch> get _filteredModules {
    return _modules.where((module) {
      final matchesSearch = module.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || module.category == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Search Bar
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: palette.black, width: 0.8),
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Search',
              
              hintStyle: TextStyle(
                color: palette.black,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                fontFamily: 'Lexend',
                fontVariations: [
                  FontVariation('wght', 300),
                ],
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(3.0),
                child: tabler.Search(strokeWidth: 1.2,),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 13, ),
            ),
          ),
        ),
        
        const SizedBox(height: 14),
        
        // Filter Chips
        Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 8),
            _buildFilterChip('Sales'),
            const SizedBox(width: 8),
            _buildFilterChip('Accounting'),
            const SizedBox(width: 8),
            _buildFilterChip('Inventory'),
          ],
        ),
        
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
                        child: SizedBox(height: mapUniformScale(12, 30, width, height)),
                      ),

                      SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return BranchCard(
                              isA: index.isEven,
                              branch: _filteredModules[index],
                            );
                          },
                          childCount: _filteredModules.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 337,
                          mainAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 260 / 226,
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


