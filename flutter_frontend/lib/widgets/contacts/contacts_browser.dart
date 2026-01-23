import 'package:flutter/material.dart';
import 'package:flutter_frontend/models/contact_model.dart';
import 'package:flutter_frontend/utils/map_function.dart';
import 'package:flutter_frontend/widgets/contacts/contact_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_scroll_multiplatform/smooth_scroll_multiplatform.dart';

class ContactsBrowser extends ConsumerStatefulWidget {
  final List<ContactModel> contacts;
  final String letter;
  final bool layoutIsPortrait;
  
  const ContactsBrowser({super.key, required this.contacts, required this.letter, required this.layoutIsPortrait});

  @override
  ConsumerState<ContactsBrowser> createState() => _ContactsBrowserState();
}

class _ContactsBrowserState extends ConsumerState<ContactsBrowser> {
  String _searchQuery = '';
  late List<ContactModel> _filteredContacts;
  ScrollController? _scrollController;
  static const double _itemHeight = 270;
  
  double _gridWidth =0;

  @override
  void initState() {
    super.initState();
    _updateFilteredContacts();
  }

  @override
  void didUpdateWidget(ContactsBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contacts != widget.contacts) {
      _updateFilteredContacts();
    }
    if (oldWidget.letter != widget.letter) {
      scrollToLetter(widget.letter);
    }
  }
  
  void scrollToTop() {
    _scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void scrollToLetter(String letter) {
    final index = _filteredContacts.indexWhere((c) =>
        (c.name ?? '').toLowerCase().startsWith(letter.toLowerCase()));

    if (index == -1) return;

    final double gridWidth = _gridWidth;

const double maxCrossAxisExtent = 400;
const double crossAxisSpacing = 12;
const double mainAxisSpacing = 12;

int crossAxisCount =
    ((gridWidth + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing))
        .ceil()
        .clamp(1, 999999);


    final int rowIndex = index ~/ crossAxisCount;
    final double rowHeight = _itemHeight + mainAxisSpacing;
    // print('crossAxisCount: $crossAxisCount');
    // print('crossAxisCount: ${((gridWidth + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing))}');
    final double targetOffset = (rowIndex * rowHeight);

    _scrollController?.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }


  void _updateFilteredContacts() {
    _filteredContacts = widget.contacts.where((contact) {
      final matchesSearch = contact.name?.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch ?? false;
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    print('rebuilding contacts_browser');
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        
        // Module Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _gridWidth = constraints.maxWidth;
              return ScrollConfiguration(
                behavior: ScrollBehavior().copyWith(scrollbars: false),
                child: DynMouseScroll(
                  durationMS: 500,
                  scrollSpeed: 1,
                  builder: (context, controller, physics) {
                    if (!identical(_scrollController, controller)) {
                      _scrollController = controller;
                    }
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
                        cacheExtent: 1200 ,
                        slivers: [
                          // TOP SCROLLING SPACER (replaces your SizedBox)
                          SliverToBoxAdapter(
                            child: SizedBox(height: mapUniformScale(20, 38, width, height)),
                          ),
                  
                          SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return ContactCard(
                                  key: ValueKey(_filteredContacts[index].id),
                                  contact: _filteredContacts[index],
                                );
                              },
                              childCount: _filteredContacts.length,
                              addAutomaticKeepAlives: true,
                              addRepaintBoundaries: true, // We're adding manually above
                            ),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 400,
                              mainAxisExtent: _itemHeight,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.1,
                            ),
                          ),
                  
                          // BOTTOM SCROLLING SPACER
                          SliverToBoxAdapter(
                            child: SizedBox(height: widget.layoutIsPortrait ? 80 : 24),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
          ),
        ),
      ],
    );
  }

}


