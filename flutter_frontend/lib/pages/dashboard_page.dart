import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/contacts/contacts_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${user?.fullName ?? user?.email ?? 'User'}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('Role: ${user?.role ?? 'Unknown'}'),
            const SizedBox(height: 16),
            Text('Company ID: ${user?.companyId ?? 'Unknown'}'),

            ElevatedButton.icon(
              icon: Icon(Icons.contacts),
              label: Text('Open Contacts'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
