import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/branch_model.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/decorated_icon.dart';
import 'package:flutter_frontend/widgets/icons/svg_icons.dart';
import 'package:flutter_frontend/widgets/sidebar/branch_card.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;

class BranchBrowser extends StatefulWidget {
  const BranchBrowser({super.key});

  @override
  State<BranchBrowser> createState() => _BranchBrowserState();
}

class _BranchBrowserState extends State<BranchBrowser> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Branch> _modules = [
    Branch(
      name: 'contacts',
      category: 'Sales',
      icon: tabler.User(),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB8E6F5), Color(0xFF7EC8E3)],
      ),
      hasImage: true,
      imageUrl: 'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400',
    ),
    Branch(
      name: 'threads',
      category: 'All',
      icon: tabler.Menu2(),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8D5C4), Color(0xFFD4BFA8)],
      ),
      hasImage: true,
      imageUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
    ),
    Branch(
      name: 'settings',
      category: 'All',
      icon: tabler.Settings(),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5A5A5A), Color(0xFF3C3C3C)],
      ),
      hasImage: false,
    ),
    Branch(
      name: 'profiles',
      category: 'Accounting',
      icon: tabler.UserUp(),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD4A5E8), Color(0xFFA87BC7)],
      ),
      hasImage: false,
    ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                fontWeight: FontWeight.w100,
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
          ],
        ),
        
        const SizedBox(height: 20),
        // Module Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: _filteredModules.map((module) => BranchCardA(branch: module,)).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? palette.extras[1] : palette.white,
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
    );
  }
}


