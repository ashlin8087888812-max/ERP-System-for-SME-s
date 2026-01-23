import 'package:flutter/material.dart';
import 'package:flutter_frontend/utils/palette.dart';

class ContactFieldItem {
  final String id;
  final String label;
  final int depth;
  final bool isHeader;

  const ContactFieldItem({
    required this.id,
    required this.label,
    required this.depth,
    this.isHeader = false,
  });
}

class ContactFieldsList extends StatefulWidget {
  const ContactFieldsList({super.key, required this.layoutIsMobile});

  final bool layoutIsMobile;

  @override
  State<ContactFieldsList> createState() => _ContactFieldsListState();
}

class _ContactFieldsListState extends State<ContactFieldsList> {
  String? _selectedId;

  // Flattened tree for memory efficiency and easy list rendering
  static const List<ContactFieldItem> _flatFields = [
    ContactFieldItem(id: 'tags', label: 'Contact Tags', depth: 0),
    ContactFieldItem(id: 'industries', label: 'Industries', depth: 0),
    ContactFieldItem(id: 'localization', label: 'Localization', depth: 0, isHeader: true),
    ContactFieldItem(id: 'countries', label: 'Countries', depth: 1),
    ContactFieldItem(id: 'states', label: 'Fed. States', depth: 1),
    ContactFieldItem(id: 'territories', label: 'Territories', depth: 1),
    ContactFieldItem(id: 'bank', label: 'Bank', depth: 0, isHeader: true),
    ContactFieldItem(id: 'banks', label: 'Banks', depth: 1),
    ContactFieldItem(id: 'accounts', label: 'Accounts', depth: 1),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4).copyWith(
        top: widget.layoutIsMobile? 10: 4,
        left: widget.layoutIsMobile? 12: 4, 
        right: widget.layoutIsMobile? 12: 4),
      decoration: BoxDecoration(
        color: palette.white,
        borderRadius: BorderRadius.circular(16),
        border: widget.layoutIsMobile
            ? Border.all(color: palette.extras[1], width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment:CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            ' Fields',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 20,
              letterSpacing: -1,
              fontWeight: FontWeight.w500,
              color: palette.extras[1],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _flatFields.length,
              itemBuilder: (context, index) {
                final item = _flatFields[index];
                return _TreeItemWidget(
                  key: ValueKey(item.id),
                  item: item,
                  isSelected: _selectedId == item.id,
                  onSelect: item.isHeader ? null : () => setState(() => _selectedId = item.id),
                  onUnselect: () => setState(() => _selectedId = null),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeItemWidget extends StatelessWidget {
  final ContactFieldItem item;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback onUnselect;

  const _TreeItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    this.onSelect,
    required this.onUnselect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: item.depth * 30.0, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(12),
          highlightColor: item.isHeader ? Colors.transparent : null,
          splashColor: item.isHeader ? Colors.transparent : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? palette.extras[0] : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 20,
                      letterSpacing: -0.5,
                      fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                      color: palette.extras[1],
                    ),
                  ),
                ),
                if (isSelected)
                  GestureDetector(
                    onTap: onUnselect,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: palette.extras[1],
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
