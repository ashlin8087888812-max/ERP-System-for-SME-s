import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

class ContactsFilter extends StatefulWidget {
  final Function(bool person, bool company) onChange;
  final bool layoutIsPortrait;
  final bool layoutIsMobile;
  const ContactsFilter({super.key, required this.onChange, required this.layoutIsPortrait, required this.layoutIsMobile});

  @override
  State<ContactsFilter> createState() => _ContactsFilterState();
}

class _ContactsFilterState extends State<ContactsFilter> {
  // Memory-efficient state storage using primitive booleans
  bool _showPeople = true;
  bool _showCompany = true;
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4).copyWith(
        top: widget.layoutIsMobile? 10: 4,
        left: widget.layoutIsMobile? 15: 4, 
        right: widget.layoutIsMobile? 12: 4),
      decoration: BoxDecoration(
        color: palette.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: widget.layoutIsMobile? CrossAxisAlignment.start: CrossAxisAlignment.center,
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
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollBehavior().copyWith(scrollbars: false),
              child: DynMouseScroll(
                durationMS: 500,
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
                    child: SingleChildScrollView(
                      controller: controller,
                      physics: widget.layoutIsMobile? physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                            layoutIsMobile: widget.layoutIsMobile,
                            layoutIsPortrait: widget.layoutIsPortrait,
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
                            layoutIsMobile: widget.layoutIsMobile,
                            layoutIsPortrait: widget.layoutIsPortrait,
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
                            layoutIsMobile: widget.layoutIsMobile,
                            layoutIsPortrait: widget.layoutIsPortrait,
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
                    ),
                  );
                }
              ),
            ),
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
  final bool layoutIsMobile;
  final bool layoutIsPortrait;

  const _FilterOption({
    required this.label,
    required this.iconPath,
    required this.isActive,
    required this.onToggle,
    required this.activeColor,
    required this.inactiveColor,
    required this.textColor,
    required this.layoutIsMobile,
    required this.layoutIsPortrait,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle switch
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
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
                      width: layoutIsMobile ? 70 : 80,
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