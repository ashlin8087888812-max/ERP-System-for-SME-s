import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactsFilter extends StatefulWidget {
  final Function(bool person, bool company) onChange;
  const ContactsFilter({super.key, required this.onChange});

  @override
  State<ContactsFilter> createState() => _ContactsFilterState();
}

class _ContactsFilterState extends State<ContactsFilter> {
  // Memory-efficient state storage using primitive booleans
  bool _showPeople = false;
  bool _showCompany = true;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Text(
            'Filters',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 20,
              letterSpacing: -1,
              fontWeight: FontWeight.w500,
              color: palette.extras[1],
            ),
          ),
          const SizedBox(height: 12),

          // Filter options
          _FilterOption(
            label: 'people',
            iconPath: 'assets/icons/person.svg',
            isActive: _showPeople,
            onToggle: () {
              setState(() {
                _showPeople = !_showPeople;
              });
              widget.onChange(_showPeople, _showCompany);
            },
            activeColor: palette.extras[1],
            inactiveColor: palette.extras[0],
            textColor: palette.extras[1],
          ),
          const SizedBox(height: 16),

          _FilterOption(
            label: 'company',
            iconPath: 'assets/icons/shop.svg',
            isActive: _showCompany,
            onToggle: () {
              setState(() {
                _showCompany = !_showCompany;
              });
              widget.onChange(_showPeople, _showCompany);
            },
            activeColor: palette.extras[1],
            inactiveColor: palette.extras[0],
            textColor: palette.extras[1],
          ),
          const SizedBox(height: 16),

          _FilterOption(
            label: 'archived',
            iconPath: 'assets/icons/archive.svg',
            isActive: _showArchived,
            onToggle: () {
              setState(() {
                _showArchived = !_showArchived;
              });
              // widget.onChange(_showArchived ? 'archived' : 'people');
            },
            activeColor: palette.extras[1],
            inactiveColor: palette.extras[0],
            textColor: palette.extras[1],
          ),
          const SizedBox(height: 12),

          // Custom filter button
          Stack(
            children: [
              SizedBox(
                height: 50,
                width: double.infinity,
              ),

              InkWell(
                onTap: () {
                  // Custom filter action
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.extras[0],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'custom',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 17,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w500,
                            color: palette.extras[1],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 5,
                child: IgnorePointer(
                  ignoring: true,
                  child: SvgPicture.asset(
                    'assets/icons/funnel.svg',
                    width: 40,
                    height: 40,
                    colorFilter: ColorFilter.mode(
                      palette.extras[1],
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Memory-efficient filter option widget using const constructor where possible
class _FilterOption extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool isActive;
  final VoidCallback onToggle;
  final Color activeColor;
  final Color inactiveColor;
  final Color textColor;

  const _FilterOption({
    required this.label,
    required this.iconPath,
    required this.isActive,
    required this.onToggle,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle switch
        Expanded(
          child: GestureDetector(
            onTap: onToggle,
            child: SizedBox(
              height: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom toggle switch
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 34,
                    decoration: BoxDecoration(
                      color: palette.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: palette.extras[1],
                        width: 1,
                      ),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isActive ? activeColor : inactiveColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label
                  Text(
                    " "+label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      letterSpacing: -1,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),

        // Icon
        Container(
          width: 50,
          height: 50,
          child: Center(
            child: SvgPicture.asset(
              iconPath,
              width:50,
              height: 50,
              colorFilter:ColorFilter.mode(
                palette.extras[1],
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}