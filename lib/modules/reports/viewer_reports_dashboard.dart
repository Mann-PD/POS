import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../authentication/auth_controller.dart';
import '../orders/order_history_screen.dart';
import 'reports_dashboard.dart';
import 'reports_service.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/user_model.dart';

/// Viewer Reports Dashboard — read-only: Sales reports, Expense summary, Order history.
/// No billing, inventory, or product edit.
class ViewerReportsDashboard extends StatefulWidget {
  const ViewerReportsDashboard({super.key});

  @override
  State<ViewerReportsDashboard> createState() => _ViewerReportsDashboardState();
}

class _ViewerReportsDashboardState extends State<ViewerReportsDashboard> {
  String? _shopId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final u = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        setState(() {
          _shopId = u.shopId;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthController().signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports (View Only)')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports (View Only)'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(context),
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Reports'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Expenses'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const ReportsDashboard(readOnly: true),
            _ViewerExpenseSummary(shopId: _shopId),
            OrderHistoryScreen(readOnly: true, shopId: _shopId),
          ],
        ),
      ),
    );
  }
}

class _ViewerExpenseSummary extends StatelessWidget {
  const _ViewerExpenseSummary({this.shopId});

  final String? shopId;

  @override
  Widget build(BuildContext context) {
    if (shopId == null || shopId!.isEmpty) {
      return const Center(child: Text('Shop not assigned'));
    }

    final reports = ReportsService();
    return StreamBuilder<List<ExpenseModel>>(
      stream: reports.streamExpenses(shopId: shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final expenses = snapshot.data ?? [];
        final total = expenses.fold(0.0, (s, e) => s + e.amount);
        final last30 = DateTime.now().subtract(const Duration(days: 30));
        final recentTotal = expenses
            .where((e) => e.createdAt.isAfter(last30))
            .fold(0.0, (s, e) => s + e.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last 30 Days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${recentTotal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Recent entries (read-only)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No expenses')),
                )
              else
                ...expenses.take(30).map(
                      (e) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            e.description.isNotEmpty ? e.description : 'Expense',
                          ),
                          subtitle: Text(
                            '${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}',
                          ),
                          trailing: Text(
                            '₹${e.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
