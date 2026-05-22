import 'package:flutter/material.dart';
import '../../routing/guarded_navigator.dart';
import '../../routing/screen_permission.dart';
import '../authentication/auth_controller.dart';
import '../admin/audit_logs_screen.dart';
import '../admin/settings_screen.dart';
import 'create_shop_screen.dart';
import 'user_management_screen.dart';
import 'shop_list_screen.dart';
import 'global_reports_screen.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthController().signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Super Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.createShop,
                    page: const CreateShopScreen(),
                  );
                },
                icon: const Icon(Icons.store),
                label: const Text('Create Shop'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a shop before creating Admin users',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.shopList,
                    page: const ShopListScreen(),
                  );
                },
                icon: const Icon(Icons.store_mall_directory),
                label: const Text('Manage Shops'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View and manage all shops in the system',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.userManagement,
                    page: const UserManagementScreen(),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('User Management'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Activate or deactivate any user account',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.globalReports,
                    page: GlobalReportsScreen(),
                  );
                },
                icon: const Icon(Icons.public),
                label: const Text('Global Reports'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cross-shop analytics for Super Admin',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.auditLogs,
                    page: const AuditLogsScreen(),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Audit Logs'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View system-wide activity and compliance logs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  GuardedNavigator.push(
                    context,
                    permission: ScreenPermission.systemSettings,
                    page: const SettingsScreen(),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('System Settings'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure global system settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
