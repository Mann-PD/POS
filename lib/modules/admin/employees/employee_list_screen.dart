import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import 'employee_controller.dart';
import 'employee_form_screen.dart';

/// Employee List Screen - Admin view of all employees
/// Allows viewing, adding, and toggling employee status
class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeController _controller = Get.put(EmployeeController());
  String? _shopId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
        _controller.setLoading(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      _controller.setLoading(false);
    }
  }

  Future<void> _toggleEmployeeStatus(UserModel employee) async {
    try {
      _controller.setLoading(true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employee.userId)
          .update({
        'status': employee.status == 'Active' ? 'Inactive' : 'Active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Employee ${employee.status == 'Active' ? 'deactivated' : 'activated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating employee: $e')),
        );
      }
    } finally {
      _controller.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employees')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeFormScreen(),
                ),
              );
            },
            tooltip: 'Add Employee',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (_controller.searchQuery.value.isNotEmpty) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _controller.clearSearchQuery(),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _controller.setSearchQuery(value),
            ),
          ),

          // Filter chips
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip('Active', 'Active'),
                    _buildFilterChip('Inactive', 'Inactive'),
                  ],
                ),
              )),

          const SizedBox(height: 8),

          // Employees list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('shopId', isEqualTo: _shopId)
                  .where('role', isEqualTo: 'Employee')
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Error loading employees: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first employee',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                final allEmployees = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(
                          doc.data() as Map<String, dynamic>,
                        ))
                    .toList();

                return Obx(() {
                  var filteredEmployees = allEmployees;

                  // Filter by search query
                  if (_controller.searchQuery.value.isNotEmpty) {
                    filteredEmployees = filteredEmployees
                        .where((employee) =>
                            employee.name
                                .toLowerCase()
                                .contains(_controller.searchQuery.value.toLowerCase()) ||
                            employee.email
                                .toLowerCase()
                                .contains(_controller.searchQuery.value.toLowerCase()) ||
                            employee.phone
                                .contains(_controller.searchQuery.value))
                        .toList();
                  }

                  // Filter by status
                  if (_controller.selectedFilter.value == 'Active') {
                    filteredEmployees = filteredEmployees
                        .where((employee) => employee.status == 'Active')
                        .toList();
                  } else if (_controller.selectedFilter.value == 'Inactive') {
                    filteredEmployees = filteredEmployees
                        .where((employee) => employee.status == 'Inactive')
                        .toList();
                  }

                  if (filteredEmployees.isEmpty) {
                    return Center(
                      child: Text(
                        'No employees match your filters',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = filteredEmployees[index];
                      return _buildEmployeeCard(context, employee);
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(label),
            selected: _controller.selectedFilter.value == value,
            onSelected: (selected) {
              if (selected) {
                _controller.setSelectedFilter(value);
              }
            },
          ),
        ));
  }

  Widget _buildEmployeeCard(BuildContext context, UserModel employee) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = employee.status == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? colorScheme.primaryContainer
              : colorScheme.errorContainer,
          child: Icon(
            isActive ? Icons.person : Icons.person_off,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onErrorContainer,
          ),
        ),
        title: Text(employee.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${employee.email}'),
            Text('Phone: ${employee.phone}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: const Text(
                    'EMPLOYEE',
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: colorScheme.secondaryContainer,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    employee.status,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: isActive
                      ? colorScheme.primaryContainer
                      : colorScheme.errorContainer,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleEmployeeStatus(employee);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
