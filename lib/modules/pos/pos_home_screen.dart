import 'package:flutter/material.dart';
import '../../core/observability/error_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pos_system/modules/pos/daily_sales_summary_screen.dart';
import 'scan_product_screen.dart';
import '../../core/firestore/firestore_pagination.dart';
import '../../core/firestore/firestore_parse.dart';
import '../../core/firestore/firestore_stream_cache.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../authentication/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'widgets/product_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/cart_fab.dart';
import 'quantity_selection_dialog.dart';
import 'cart_screen.dart';
import '../../routing/guarded_navigator.dart';
import '../../routing/permission_gate.dart';
import '../../routing/screen_permission.dart';

/// POS Home Screen - Primary working screen for employees
/// Displays products, categories, search, and cart access
class PosHomeScreen extends StatefulWidget {
  const PosHomeScreen({super.key});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String? _shopId;
  bool _isLoading = true;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _categoriesStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _productsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUserData(context);
    });
  }

  Future<void> _loadUserData(BuildContext pageContext) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (pageContext.mounted) {
          Navigator.of(pageContext).pushReplacementNamed('/login');
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

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
          _initPosStreams();
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      if (pageContext.mounted) {
        showErrorSnackBar(
          pageContext,
          e,
          stackTrace: st,
          tag: 'PosHomeScreen._loadUser',
        );
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initPosStreams() {
    if (_shopId == null || _shopId!.isEmpty) return;
    final db = FirebaseFirestore.instance;
    final cache = FirestoreStreamCache.instance;
    _categoriesStream ??= cache.querySnapshots(
      firstPageQuery(
        db
            .collection('categories')
            .where('shopId', isEqualTo: _shopId)
            .where('status', isEqualTo: 'Active')
            .orderBy('name'),
        pageSize: 200,
      ),
      key: 'pos_categories_$_shopId',
    );
    _productsStream ??= cache.querySnapshots(
      firstPageQuery(
        db
            .collection('products')
            .where('shopId', isEqualTo: _shopId)
            .where('status', isEqualTo: 'Active')
            .orderBy('name'),
        pageSize: FirestorePageSize.posCatalogCap,
      ),
      key: 'pos_products_$_shopId',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext pageContext) async {
    final confirm = await showDialog<bool>(
      context: pageContext,
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

    if (confirm != true) return;
    await AuthController().signOut();
    if (pageContext.mounted) {
      Navigator.of(pageContext).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _gridMainAxisExtent(double width) {
    if (width >= 900) return 220;
    return 200;
  }

  void _onProductTap(BuildContext pageContext, ProductModel product) async {
    // Check stock availability
    if (product.stock <= 0) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(
            content: Text('Product is out of stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (product.status != 'Active') {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          const SnackBar(
            content: Text('Product is not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show quantity selection dialog
    final quantity = await showDialog<double>(
      context: pageContext,
      builder: (context) => QuantitySelectionDialog(product: product),
    );

    if (quantity == null || quantity <= 0) return;
    try {
      final cartController = Get.find<CartController>();
      cartController.addItem(product, quantity);

      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e, st) {
      if (pageContext.mounted) {
        showErrorSnackBar(
          pageContext,
          e,
          stackTrace: st,
          tag: 'PosHomeScreen.addToCart',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: ScreenPermission.posHome,
      child: _buildPosContent(context),
    );
  }

  Widget _buildPosContent(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_shopId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text('Unable to load shop information'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _loadUserData(context),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('POS System'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              if (_shopId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shop not loaded yet'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              GuardedNavigator.push(
                context,
                permission: ScreenPermission.scanProduct,
                page: ScanProductScreen(
                  shopId: _shopId!,
                  onProductScanned: (product) =>
                      _onProductTap(context, product),
                ),
              );
            },
            tooltip: 'Scan product barcode',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              GuardedNavigator.push(
                context,
                permission: ScreenPermission.dailySalesSummary,
                page: const DailySalesSummaryScreen(),
              );
            },
            tooltip: 'Daily Sales Summary',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search and category filters
          Material(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by product name...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _categoriesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final categories = snapshot.data!.docs;
                      final categoryList = [
                        {'categoryId': 'all', 'name': 'All'},
                        ...categories
                            .map((doc) => FirestoreParse.queryDocumentData(doc))
                            .whereType<Map<String, dynamic>>(),
                      ];

                      return SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoryList.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categoryList[index];
                            final isSelected =
                                _selectedCategory ==
                                (category['categoryId'] ?? 'all');

                            return CategoryChip(
                              label: category['name'] ?? 'All',
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCategory =
                                      category['categoryId'] ?? 'all';
                                });
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productsStream,
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
                        Text('Error loading products: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(
                    context,
                    icon: Icons.inventory_2_outlined,
                    title: 'No products available',
                    subtitle: 'Products will appear here once added by admin',
                  );
                }

                // Filter products
                final allProducts = FirestoreParse.parseQueryDocs(
                  snapshot.data!.docs,
                  ProductModel.tryFromMap,
                );

                var filteredProducts = allProducts;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filteredProducts = filteredProducts
                      .where(
                        (product) =>
                            product.name.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }

                // Filter by category
                if (_selectedCategory != 'all') {
                  filteredProducts = filteredProducts
                      .where(
                        (product) => product.categoryId == _selectedCategory,
                      )
                      .toList();
                }
                // Filter out-of-stock products (show but disabled)
                // Actually, show all products but mark out-of-stock

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState(
                    context,
                    icon: Icons.search_off_rounded,
                    title: 'No products found',
                    subtitle: 'Try another search or category',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = _gridCrossAxisCount(width);
                    final mainAxisExtent = _gridMainAxisExtent(width);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              children: [
                                Text(
                                  'Products',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${filteredProducts.length} items',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Obx(
                          () => SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              cartController.isEmpty ? 16.0 : 88.0,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisExtent: mainAxisExtent,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final product = filteredProducts[index];
                                return ProductCard(
                                  product: product,
                                  onTap: () =>
                                      _onProductTap(context, product),
                                );
                              }, childCount: filteredProducts.length),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (cartController.isEmpty) return const SizedBox.shrink();
        return CartFAB(
          itemCount: cartController.itemCount,
          totalAmount: cartController.totalAmount,
          onTap: () {
            GuardedNavigator.push(
              context,
              permission: ScreenPermission.cart,
              page: const CartScreen(),
            );
          },
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
