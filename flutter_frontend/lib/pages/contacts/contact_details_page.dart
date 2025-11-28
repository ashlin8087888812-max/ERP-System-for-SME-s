// lib/pages/contact_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_frontend/providers/contacts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactDetailPage extends ConsumerWidget {
  final int contactId;
  const ContactDetailPage({required this.contactId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactDetailProvider(contactId));

    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: contactAsync.when(
        data: (c) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name ?? 'Unnamed', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Email: ${c.email ?? '-'}'),
              const SizedBox(height: 8),
              Text('Phone: ${c.phone ?? '-'}'),
              const SizedBox(height: 8),
              Text('Company: ${c.companyName ?? '-'}'),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
