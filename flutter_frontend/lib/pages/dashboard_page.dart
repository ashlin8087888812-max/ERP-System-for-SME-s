import 'package:flutter/material.dart';
import 'package:flutter_frontend/pages/utils/adaptive_layout.dart';
import 'package:flutter_frontend/pages/utils/layout_tier.dart';
import 'package:tabler_icons_next/tabler_icons_next.dart' as tabler;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final layoutTier = ref.watch(layoutTierProvider);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Dashboard'),
      //   leading: IconButton(
      //     icon: const tabler.Menu3(
            
      //     ),
      //     onPressed: () {
      //       context.push('/menu');
      //     },
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: () {
      //         ref.read(authProvider.notifier).logout();
      //       },
      //     ),
      //   ],
      // ),
      body: AdaptiveLayout(
        child: Stack(
          children: [
            
            Center(
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
                      context.go('/contacts');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
