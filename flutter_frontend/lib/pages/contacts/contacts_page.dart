import 'dart:async';
import 'package:alphabet_scrollbar/alphabet_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/contacts/contacts_filter.dart';
import 'package:flutter_frontend/utils/adaptive_layout.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/map_function.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/utils/sized_box_ops.dart';
import 'package:flutter_frontend/widgets/contacts/contact_add.dart';
import 'package:flutter_frontend/widgets/contacts/contact_fields_list.dart';
import 'package:flutter_frontend/widgets/contacts/contacts_browser.dart';
import 'package:flutter_frontend/widgets/contacts/contacts_export.dart';
import 'package:flutter_frontend/widgets/contacts/contacts_title.dart';
import 'package:flutter_frontend/widgets/navbar.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:flutter_frontend/widgets/icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/titles/gestace_title.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;
import '../../providers/contacts_provider.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  String _selectedType = 'both'; // Filter: 'both', 'person', 'company'
  String _selectedGroup = 'All';
  final ValueNotifier<String> _selectedLetter = ValueNotifier("A");


  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final layoutTier = ref.watch(layoutTierProvider);
    final layoutOrientation = ref.watch(layoutOrientationProvider);
    final layoutIsMobile = layoutTier == LayoutTier.compact || layoutTier == LayoutTier.mobile;
    final layoutIsDesktop = layoutTier == LayoutTier.tablet || layoutTier == LayoutTier.desktop;
    final layoutIsPortrait = layoutOrientation == Orientation.portrait && layoutIsMobile;
    final layoutIsLandscape = layoutOrientation == Orientation.landscape && layoutIsMobile;
    const SizedBox spacing  = SizedBox(height: 15);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    Size navbarSize = Size(60,60);
    Size filterbarSize = Size(200,60);
    // Build filter params
    final filter = ContactsQuery(
      q: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _selectedType,
      limit: 50,
      offset: 0,
    );
    
    final contactsAsync = ref.watch(contactsListProvider(filter));

    return Scaffold(
      backgroundColor: palette.white,
      body: AdaptiveLayout(
        child: Stack(
          children: [
            //Browser
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile
                ? layoutIsPortrait
                  ? 60
                  : width/2
                : (navbarSize.width+filterbarSize.width+20),
              top: layoutIsMobile
              ? layoutIsPortrait
                  ? 250
                  : 0
              : 380,
              width: layoutIsMobile
                ? layoutIsPortrait
                  ? width-85 
                  : width/2-25
                : (width-navbarSize.width-filterbarSize.width-45),
              height: height - (layoutIsMobile
                ? layoutIsPortrait
                  ? 250
                  : 0
                :380),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  
                  Expanded(
                    child: contactsAsync.when(
                      data: (contacts) {
                        if (contacts.isEmpty) {
                          return const Center(child: Text('No contacts found'));
                        }
                        return ValueListenableBuilder<String>(
                          valueListenable: _selectedLetter,
                          builder: (context, letter, _) {
                            return ContactsBrowser(
                              contacts: contacts,
                              letter: letter,
                              layoutIsPortrait: layoutIsPortrait,
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
            //Title, serach and Menus
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile
                ? layoutIsPortrait
                  ? 25
                  : navbarSize.width+15
                : navbarSize.width+filterbarSize.width+20,
              top:0,
              width: layoutIsMobile 
                ? layoutIsPortrait
                  ? width-60
                  : width/2 -100
                : width-navbarSize.width-filterbarSize.width-45,
              height:layoutIsMobile
                ? layoutIsPortrait
                  ? 250 
                  : 240
                : 380,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: SizedBox(
                          height: layoutIsMobile
                            ? layoutIsPortrait
                              ? 250 
                              : 240
                            : 380,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              spacing+mapUniformScale(45, 20, width,height),
                              //Contacts title
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.topCenter,
                                        padding: EdgeInsets.only(left:layoutIsMobile
                                        ? layoutIsPortrait
                                          ? 0
                                          : 5
                                        : 0,
                                        right:layoutIsMobile
                                        ? layoutIsPortrait
                                          ? 20 
                                          : 10
                                        : mapUniformScale(80, 150, width,height)),
                                        child: ContactsTitle(scale: layoutIsMobile
                                          ? 1.5
                                          : mapUniformScale(1, 3, width,height)),
                                      ),
                                    ),
                                    if (layoutIsPortrait)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: palette.extras[1],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: palette.black, width: 0.8),
                                      ),
                                      padding: EdgeInsets.all(10),
                                      child: tabler.SitemapFilled(
                                        strokeWidth: 1,
                                        color: palette.white,
                                        width: 50,
                                        height: 50,
                                        
                                      ),
                                    ),
                                      
                                  ],
                                ),
                              ),
                              // Search Bar
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: mapUniformScale(40, 60, width,height),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        border: Border.all(color: palette.black, width: 0.8),
                                      ),
                                      child: TextField(
                                        onChanged: (value) => _onSearchChanged(value),
                                        controller: _searchController,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: TextStyle(
                                            color: palette.black,
                                            fontSize: mapUniformScale(24, 32, width,height),
                                            fontWeight: layoutIsPortrait? FontWeight.w300: FontWeight.w200,
                                            fontFamily: 'Lexend',
                                            fontVariations: [
                                              FontVariation('wght', 300),
                                            ],
                                          ),
                                        decoration: InputDecoration(
                                          hintText: 'Search',
                                          
                                          hintStyle: TextStyle(
                                            color: palette.black,
                                            fontSize: mapUniformScale(24, 32, width,height),
                                            fontWeight: FontWeight.w200,
                                            fontFamily: 'Lexend',
                                            fontVariations: [
                                              FontVariation('wght', 300),
                                            ],
                                          ),
                                          prefixIcon: Padding(
                                            padding: EdgeInsets.only(left: 15,top: mapUniformScale(2, 5, width,height),right: 5),
                                            child: tabler.Search(strokeWidth: 0.6,width: mapUniformScale(24, 50, width,height),height: mapUniformScale(24, 50, width,height),),
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if(layoutIsPortrait)
                                  InkWell(
                                    onTap: () {
                                      
                                    },
                                    child: SvgPicture.asset('assets/icons/funnel.svg',
                                    width: 45,
                                    height: 45,),
                                  )
                                ],
                              ),
                              spacing,
                              //Group by Chips
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentGeometry.topLeft,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text('Group By:',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w200,
                                      fontFamily: 'Lexend',
                                      fontVariations: [
                                        FontVariation('wght', 300),
                                      ],
                                    ),),
                                    const SizedBox(width: 8),
                                    _buildGroupChip('All'),
                                    const SizedBox(width: 8),
                                    _buildGroupChip('Sales'),
                                    const SizedBox(width: 8),
                                    _buildGroupChip('Accounting'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                      if(!layoutIsMobile)
                      Expanded(
                        flex: 10,
                        child: Container(
                          padding: EdgeInsets.all(12),

                          height: 380,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentGeometry.topRight,
                            child: Container(
                              height: 480,
                              width: 240,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: palette.black),
                              ),
                              child: ContactFieldsList(layoutIsMobile: layoutIsMobile,)),
                          ),
                        )),
                    ],
                  ),
                ],
              ),
            ),
            //navbar
            AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                left: layoutIsMobile? layoutIsPortrait? 14:0:8,
                bottom: layoutIsMobile? 0:10,
                width: layoutIsPortrait? width-14:navbarSize.width,
                height: layoutIsPortrait? navbarSize.height:height - 30,
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
                          if(layoutIsDesktop){
                            context.go('/dashboard?sidebar=open');
                          } else {
                            context.go('/menu');
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: layoutIsPortrait? 0:10,left: layoutIsPortrait? 10:0),
                        child: Navbar(
                          size: navbarSize,
                          sidebar: false,
                          page: AppPage.contacts,
                        )
                      ),
                    )
                  ],
                )
              ),
            //filter and operation buttons
            if(!layoutIsPortrait)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile
                ? layoutIsPortrait
                  ? 14
                  : navbarSize.width+8
                : navbarSize.width+8,
              top: layoutIsMobile
                ? layoutIsPortrait
                  ? null
                  : 240 +15
                : null,
              bottom: layoutIsMobile
                ? layoutIsPortrait
                  ? filterbarSize.height
                  : null
                : 0,
              width: layoutIsMobile
                ? layoutIsPortrait
                  ? width-14
                  : width/2 -80
                : filterbarSize.width,
              height: layoutIsMobile? layoutIsPortrait
                ? navbarSize.height
                : height-240-30
                : height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: layoutIsMobile? 12: 24),
                child: Flex(
                  direction: layoutIsMobile? Axis.horizontal: Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Gestace Title
                    if(!layoutIsMobile)
                    InnerShadow(
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
                        width:filterbarSize.width,
                        height: filterbarSize.height,
                        decoration: BoxDecoration(
                          color: palette.extras[0],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(0),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          )
                        ),
                        padding: const EdgeInsets.only(top: 10,bottom: 15),
                        child: FittedBox(child: GestaceTitle()),
                      ),
                    ),
                    spacing,
                    //Contacts Filter
                    layoutIsMobile? Expanded(
                      flex: 15,
                      child:  Container(
                        decoration: BoxDecoration(
                          color: palette.white,
                          borderRadius: BorderRadius.circular(16),
                          border: layoutIsMobile? Border.all(color: palette.extras[1], width: 1): null,
                        ),
                        child: ContactsFilter(
                          layoutIsPortrait: layoutIsPortrait,
                          layoutIsMobile: layoutIsMobile,
                          onChange: (person, company) {
                            if (person && company){
                              _selectedType = 'both';
                            } else if (person && !company){
                              _selectedType = 'person';
                            } else if (!person && company){
                              _selectedType = 'company';
                            }
                            setState(() {
                            });
                          },
                        ),
                      ),
                    ):SizedBox(
                      height:310,
                      child: ContactsFilter(
                        layoutIsPortrait: layoutIsPortrait,
                        layoutIsMobile: layoutIsMobile,
                        onChange: (person, company) {
                          if (person && company){
                            _selectedType = 'both';
                          } else if (person && !company){
                            _selectedType = 'person';
                          } else if (!person && company){
                            _selectedType = 'company';
                          }
                          setState(() {
                          });
                        },
                      ),
                    ),
                    SizedBox(height: mapUniformScale(10, 15, width, height),width: 10,),

                    if(layoutIsMobile)
                    Expanded( flex: 15, child: ContactFieldsList(layoutIsMobile: layoutIsMobile)),
                    SizedBox(height: mapUniformScale(3,  21, width, height),width: 10,),
                    //Add & Export Contact Button
                    Expanded(
                      flex: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          layoutIsMobile? ContactAddMini(): ContactAdd(),
                          spacing,
                          //Export Button
                          layoutIsMobile? ContactExportMini(): Expanded(child: ContactExport()),
                          spacing,
                        ],
                      ),
                    ),
                  ],
                )
              ),
            ),
            //alphabet scrollbar
            Positioned(
                right: 6,
                top: 0,
                height: height - (layoutIsPortrait? navbarSize.height:0),
                child: AlphabetScrollbar(
                  //onLetterChange is needed and should contain a Function(String letter), where you handle your Scrolling. 
                  onLetterChange: (value) {
                    _selectedLetter.value = value;
                  },
                  reverse: false, //optional. would Reverse the Order (Z-A).
                  switchToHorizontal: false, //optional. makes the Scrollbar Horizontally not Verticaly.
                  factor: 10,
                  //optional. changes the side to left (if switchToHorizontal also True,Switches to Top)
                  leftSidedOrTop: false, 
                  selectedLetterSize: 55,
                  selectedLetterColor: palette.white,
                  selectedLettercontainerPadding: EdgeInsets.all(12),
                  selectedLetterContainerDecoration: BoxDecoration(
                    color: palette.extras[1],
                    border: Border.all(
                      color: palette.white,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.extras[1].withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: palette.black,
                    fontSize: 14,
                    letterSpacing: -0.2,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w300,
                    fontVariations: [
                      FontVariation('wght', 300),
                    ],
                  ),
                ),
              )
            
          ],
        ),
      ),
    );
  }
  Widget _buildGroupChip(String label) {
    final isSelected = _selectedGroup == label;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: isSelected ? palette.extras[1] : palette.white,
        child: InkWell(
          onTap: () => setState(() => _selectedGroup = label),
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
                fontWeight: FontWeight.w300,
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

