import 'dart:convert';
import 'dart:async';
import 'package:alphabet_scrollbar/alphabet_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/contacts/contacts_filter.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';
import 'package:flutter_frontend/utils/adaptive_layout.dart';
import 'package:flutter_frontend/utils/app_page.dart';
import 'package:flutter_frontend/utils/layout_tier.dart';
import 'package:flutter_frontend/utils/palette.dart';
import 'package:flutter_frontend/widgets/contacts/contact_card.dart';
import 'package:flutter_frontend/widgets/contacts/contacts_browser.dart';
import 'package:flutter_frontend/widgets/contacts/contacts_title.dart';
import 'package:flutter_frontend/widgets/dashboard/navbar.dart';
import 'package:flutter_frontend/widgets/hover_icon.dart';
import 'package:flutter_frontend/widgets/icons/menu_icon.dart';
import 'package:flutter_frontend/widgets/titles/gestace_title.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;
import '../../providers/contacts_provider.dart';
import '../../models/contact_model.dart';

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
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => context.go('/dashboard'),
        //   tooltip: 'Back to Dashboard',
        // ),
        // title: const Text('Contacts'),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(60),
        //   child: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: TextField(
        //       controller: _searchController,
        //       decoration: InputDecoration(
        //         hintText: 'Search contacts...',
        //         prefixIcon: const Icon(Icons.search),
        //         border: OutlineInputBorder(
        //           borderRadius: BorderRadius.circular(10),
        //           borderSide: BorderSide.none,
        //         ),
        //         filled: true,
        //         fillColor: Colors.white,
        //         contentPadding: const EdgeInsets.symmetric(vertical: 0),
        //       ),
        //       onChanged: _onSearchChanged,
        //     ),
        //   ),
        // ),
        actions: [
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter contacts',
            initialValue: _selectedType,
            onSelected: (String value) {
              setState(() {
                _selectedType = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'both',
                child: Text('All Contacts'),
              ),
              const PopupMenuItem<String>(
                value: 'person',
                child: Text('Persons Only'),
              ),
              const PopupMenuItem<String>(
                value: 'company',
                child: Text('Companies Only'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/contacts/new');
            },
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: AdaptiveLayout(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left:navbarSize.width+filterbarSize.width+20,
              bottom: layoutIsMobile? 0:0,
              width: width-navbarSize.width-filterbarSize.width-45,
              height: height - (layoutIsPortrait? navbarSize.height:0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: SizedBox(
                          height: 380,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.topCenter,
                                  padding: const EdgeInsets.only(left: 0,right: 150),
                                  child: const ContactsTitle(),
                                ),
                              ),
                              // Search Bar
                              Container(
                                height: 60,
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
                                      fontSize: 32,
                                      fontWeight: FontWeight.w200,
                                      fontFamily: 'Lexend',
                                      fontVariations: [
                                        FontVariation('wght', 300),
                                      ],
                                    ),
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    
                                    hintStyle: TextStyle(
                                      color: palette.black,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w200,
                                      fontFamily: 'Lexend',
                                      fontVariations: [
                                        FontVariation('wght', 300),
                                      ],
                                    ),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 15,top: 5,right: 5),
                                      child: tabler.Search(strokeWidth: 0.6,width: 50,height: 50,),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              spacing,
                              Row(
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
                            ],
                          ),
                        )),
                      Expanded(
                        flex: 10,
                        child: const Placeholder(
                          fallbackHeight: 320,
                        )),
                    ],
                  ),
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: layoutIsMobile
                  ? layoutIsPortrait
                    ? 14
                    : -navbarSize.width
                  : navbarSize.width+8,
              bottom: layoutIsMobile? filterbarSize.height:0,
              width: layoutIsPortrait? width-14:filterbarSize.width,
              height: layoutIsPortrait? navbarSize.height:height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
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
                    ContactsFilter(
                      onChange: (person, company) {
                        if (person){
                          _selectedType = 'people';
                        } else if (company){
                          _selectedType = 'company';
                        }
                        setState(() {
                          _showPeople = person;
                          _showCompany = company;
                        });
                      },
                    ),
                  ],
                )
              ),
            ),
            Positioned(
                right: 6,
                height: height - (layoutIsMobile? navbarSize.height:0),
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

