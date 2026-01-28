import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../pages/login_page.dart';
import '../providers/auth_provider.dart';
import '../pages/dashboard_page.dart';
import '../pages/contacts/contacts_page.dart';
import '../pages/contacts/contact_form_page.dart';
import '../pages/contacts/contact_details_page.dart';
import '../pages/sidebar_menu.dart';
import '../pages/threads/threads_page.dart';

class AppRouter {
  static GoRouter router(Ref ref) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefresh(ref),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => DashboardPage(sidebar: false),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final sidebar = state.uri.queryParameters['sidebar'];
            final sidebarOpen = sidebar == 'open'; // anything else → false

            return DashboardPage(sidebar: sidebarOpen);
          },
        ),
        GoRoute(
          path: '/contacts',
          builder: (context, state) => const ContactsPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ContactFormPage(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return ContactDetailsPage(contactId: id);
              },
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                    return ContactFormPage(contactId: id);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/threads',
          builder: (context, state) => const ThreadsPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? 'mail.box_inbox';
                return ThreadsPage(threadId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) => const SidebarMenu(),
        ),
      ],
    );
  }
}
