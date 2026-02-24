import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';

/// Super Admin only: list all users and set status (Active / Inactive / Suspended).
/// Use this to activate accounts that are stuck "inactive".
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String userId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status set to $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users in the system.'));
          }
          final users = docs
              .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
              .toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isActive = user.status == 'Active';
              final isSuspended = user.status == 'Suspended';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Text('${user.role} • ${user.shopId.isEmpty ? "—" : user.shopId}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(user.status),
                            backgroundColor: isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : isSuspended
                                    ? Theme.of(context).colorScheme.errorContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'Change status',
                            onSelected: (value) => _updateStatus(context, user.userId, value),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Active', child: Text('Set Active')),
                              const PopupMenuItem(value: 'Inactive', child: Text('Set Inactive')),
                              const PopupMenuItem(value: 'Suspended', child: Text('Set Suspended')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
