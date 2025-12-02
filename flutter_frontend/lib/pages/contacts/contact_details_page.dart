import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contacts_provider.dart';
import '../../models/contact_model.dart';
import 'package:go_router/go_router.dart';

class ContactDetailsPage extends ConsumerWidget {
  final int contactId;

  const ContactDetailsPage({super.key, required this.contactId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactDetailProvider(contactId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Details'),
        actions: [
          contactAsync.when(
            data: (contact) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.go('/contacts/$contactId/edit');
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: contactAsync.when(
        data: (contact) => _ContactDetailView(contact: contact),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  final ContactModel contact;

  const _ContactDetailView({required this.contact});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(context),
        const Divider(),
        _buildSection(
          'General Information',
          [
            _buildInfoRow('Type', contact.isCompany ? 'Company' : 'Person'),
            if (contact.parentId != null)
              _buildRelationRow(context, 'Company/Parent', contact.parentId!),
            _buildInfoRow('Address', _formatAddress(contact)),
            _buildInfoRow('Website', contact.website),
            _buildInfoRow('Job Position', contact.function),
            _buildInfoRow('Tax ID', contact.vat),
            if (contact.categoryId.isNotEmpty)
              _buildTagsRow('Tags', contact.categoryId),
          ],
        ),
        const Divider(),
        _buildSection(
          'Communication',
          [
            _buildInfoRow('Phone', contact.phone),
            _buildInfoRow('Mobile', contact.mobile),
            _buildInfoRow('Email', contact.email),
          ],
        ),
        if (contact.childIds.isNotEmpty) ...[
          const Divider(),
          _buildChildrenSection(context),
        ],
        if (contact.comment != null && contact.comment!.isNotEmpty) ...[
          const Divider(),
          _buildSection(
            'Internal Notes',
            [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(contact.comment!),
              ),
            ],
          ),
        ],
        const Divider(),
        _buildSection(
          'System Data',
          [
            _buildInfoRow('Created', contact.createDate),
            _buildInfoRow('Last Updated', contact.writeDate),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget imageWidget;
    if (contact.image1920 != null && contact.image1920!.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(contact.image1920!),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      } catch (e) {
        imageWidget = const Icon(Icons.person, size: 80, color: Colors.grey);
      }
    } else if (contact.image128 != null && contact.image128!.isNotEmpty) {
      try {
        imageWidget = Image.memory(
          base64Decode(contact.image128!),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        );
      } catch (e) {
        imageWidget = const Icon(Icons.person, size: 80, color: Colors.grey);
      }
    } else {
      imageWidget = Icon(
        contact.isCompany ? Icons.business : Icons.person,
        size: 80,
        color: Colors.grey,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Container(
              width: 120,
              height: 120,
              color: Colors.grey[200],
              child: imageWidget,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.displayName ?? contact.name ?? 'No Name',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (contact.companyName != null && !contact.isCompany)
                  Text(
                    contact.companyName!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (contact.active)
                      const Chip(
                        label: Text('Active'),
                        backgroundColor: Colors.greenAccent,
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      const Chip(
                        label: Text('Archived'),
                        backgroundColor: Colors.grey,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (contact.isCompany) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('Company'),
                        backgroundColor: Colors.blueAccent,
                        labelStyle: TextStyle(color: Colors.white),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChildrenSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contact.childIds.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final child = contact.childIds[index];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(child.name ?? 'Contact #${child.id}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to child contact
                  context.push('/contacts/${child.id}');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationRow(BuildContext context, String label, RelationField relation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/contacts/${relation.id}'),
              child: Text(
                relation.name ?? 'ID: ${relation.id}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(String label, List<RelationField> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags.map((tag) => Chip(
                label: Text(tag.name ?? '${tag.id}'),
                visualDensity: VisualDensity.compact,
                backgroundColor: Colors.grey[200],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(ContactModel c) {
    final parts = [
      c.street,
      c.street2,
      c.city,
      c.stateId?.name,
      c.zip,
      c.countryId?.name,
    ];
    return parts.where((p) => p != null && p.toString().isNotEmpty).join(', ');
  }
}
