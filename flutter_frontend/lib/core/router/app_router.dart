import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/admin_dashboard.dart';
import '../../features/dashboard/presentation/pages/supervisor_dashboard.dart';
import '../../features/dashboard/presentation/pages/worker_dashboard.dart';
import '../../features/dashboard/presentation/pages/driver_dashboard.dart';
import '../../features/inventory/presentation/pages/purchase_order_list_page.dart';
import '../../features/inventory/presentation/pages/grn_scan_page.dart';
import '../../features/inventory/presentation/pages/stock_inventory_page.dart';
import '../../features/production/presentation/pages/job_card_page.dart';
import '../../features/production/presentation/pages/stage_execution_page.dart';
import '../../features/sales/presentation/pages/picking_page.dart';

class AppRouter {
  static GoRouter router(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        // If not authenticated and not on login page, redirect to login
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        // If authenticated and on login page, redirect to admin dashboard
        if (isAuthenticated && isLoggingIn) {
          return '/dashboard/admin';
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        // Dashboards
        GoRoute(
          path: '/dashboard/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/dashboard/supervisor',
          builder: (context, state) => const SupervisorDashboard(),
        ),
        GoRoute(
          path: '/dashboard/worker',
          builder: (context, state) => const WorkerDashboard(),
        ),
        GoRoute(
          path: '/dashboard/driver',
          builder: (context, state) => const DriverDashboard(),
        ),
        // Inventory
        GoRoute(
          path: '/inventory/po',
          builder: (context, state) => const PurchaseOrderListPage(),
        ),
        GoRoute(
          path: '/inventory/grn',
          builder: (context, state) => const GRNScanPage(),
        ),
        GoRoute(
          path: '/inventory/stock',
          builder: (context, state) => const StockInventoryPage(),
        ),
        // Production
        GoRoute(
          path: '/production/job',
          builder: (context, state) => const JobCardPage(),
        ),
        GoRoute(
          path: '/production/stage',
          builder: (context, state) => const StageExecutionPage(),
        ),
        // Sales
        GoRoute(
          path: '/sales/picking',
          builder: (context, state) => const PickingPage(),
        ),
      ],
    );
  }
}
