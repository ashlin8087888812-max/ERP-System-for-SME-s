// lib/pages/contacts_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_frontend/providers/contacts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contact_details_page.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  String? _q;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final params = {'q': _q, 'limit': 50, 'offset': 0};
    final contactsAsync = ref.watch(contactsListProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Search contacts'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _q = _controller.text.trim().isEmpty ? null : _controller.text.trim();
                    });
                  },
                )
              ],
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              data: (list) => ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final c = list[idx];
                  return ListTile(
                    title: Text(c.name ?? 'Unnamed'),
                    subtitle: Text(c.email ?? c.phone ?? ''),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ContactDetailPage(contactId: c.id)),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
