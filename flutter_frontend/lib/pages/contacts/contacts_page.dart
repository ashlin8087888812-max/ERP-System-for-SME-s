import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    // Build filter params
    final filter = ContactsFilter(
      q: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _selectedType,
      limit: 50,
      offset: 0,
    );
    
    final contactsAsync = ref.watch(contactsListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: const Text('Contacts'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
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
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _ContactCard(contact: contact);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ContactModel contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    // Determine icon based on isCompany
    final icon = contact.isCompany ? Icons.business : Icons.person;
    final iconColor = contact.isCompany ? Colors.blue : Colors.green;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: contact.image128 != null && contact.image128!.isNotEmpty
            ? ClipOval(
                child: Image.memory(
                  base64Decode(contact.image128!),
                  fit: BoxFit.cover,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => Icon(icon, color: iconColor),
                ),
              )
            : Icon(icon, color: iconColor),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.displayName ?? contact.name ?? 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (contact.isCompany)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'COMPANY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        contact.email ?? contact.phone ?? contact.city ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go('/contacts/${contact.id}'),
    );
  }
}
