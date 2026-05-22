import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/customer_model.dart';
import '../../../widgets/firestore_paginated_list.dart';
import '../../../data/models/user_model.dart';
import '../../../routing/guarded_navigator.dart';
import '../../../routing/screen_permission.dart';
import 'customer_detail_screen.dart';

/// Customer List Screen - Admin view of all customers
/// Allows viewing customers, searching, and opening customer details.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String? _shopId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = UserModel.tryFromDocument(userDoc);
        if (userData == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          return;
        }
        if (!mounted) return;
        setState(() {
          _shopId = userData.shopId;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customers')),
        body: const Center(child: Text('Shop not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or mobile...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),

          Expanded(
            child: FirestorePaginatedList<CustomerModel>(
              cacheKey: 'customers_shop_$_shopId',
              queryBuilder: () => FirebaseFirestore.instance
                  .collection('customers')
                  .where('shopId', isEqualTo: _shopId)
                  .orderBy('name'),
              parse: (data, _) => CustomerModel.tryFromMap(data),
              itemKey: (c) => c.customerId,
              filterItems: (items) {
                if (_searchQuery.isEmpty) return items;
                final q = _searchQuery.toLowerCase();
                return items
                    .where(
                      (c) =>
                          c.name.toLowerCase().contains(q) ||
                          c.mobile.contains(_searchQuery),
                    )
                    .toList();
              },
              emptyBuilder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No customers found'
                          : 'No customers match your search',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context, customer) =>
                  _buildCustomerCard(context, customer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel customer) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person_outline,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(customer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Mobile: ${customer.mobile}'),
            const SizedBox(height: 4),
            const Text('Open for order history'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          GuardedNavigator.push(
            context,
            permission: ScreenPermission.customerDetail,
            page: CustomerDetailScreen(
              customer: customer,
              shopId: _shopId!,
            ),
          );
        },
      ),
    );
  }
}

