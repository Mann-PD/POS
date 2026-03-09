import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/user_model.dart';
import 'category_form_screen.dart';

/// Category List Screen - Admin view of all categories for a shop.
/// Allows viewing, creating, editing, and enabling/disabling categories.
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String? _shopId;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserShop();
  }

  Future<void> _loadUserShop() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
        );
        setState(() {
          _shopId = userData.shopId;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(CategoryModel category) async {
    final newStatus =
        category.status == 'Active' ? 'Inactive' : 'Active';
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(category.categoryId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category ${newStatus == 'Active' ? 'enabled' : 'disabled'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shopId == null || _shopId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: const Center(child: Text('Shop not assigned')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryFormScreen(
                    shopId: _shopId!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search categories...',
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .where('shopId', isEqualTo: _shopId)
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading categories: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No categories found',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first category',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allCategories = snapshot.data!.docs
                    .map(
                      (doc) => CategoryModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .toList();

                List<CategoryModel> filtered = allCategories;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = allCategories
                      .where(
                        (c) => c.name.toLowerCase().contains(q),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No categories match your search',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final category = filtered[index];
                    final isActive = category.status == 'Active';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? colorScheme.primaryContainer
                              : colorScheme.errorContainer,
                          child: Icon(
                            Icons.category,
                            color: isActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onErrorContainer,
                          ),
                        ),
                        title: Text(category.name),
                        subtitle: Text(
                          'Status: ${category.status}',
                          style: TextStyle(
                            color: isActive
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (_) =>
                                  _toggleStatus(category),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.edit, size: 20),
                              tooltip: 'Edit',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CategoryFormScreen(
                                      shopId: _shopId!,
                                      category: category,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

