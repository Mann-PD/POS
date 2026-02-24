import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'data/models/user_model.dart';
import 'modules/authentication/auth_controller.dart';
import 'modules/authentication/login_screen.dart';
import 'modules/authentication/inactivity_wrapper.dart';
import 'modules/authentication/session_manager.dart';
import 'modules/pos/pos_home_screen.dart';
import 'modules/pos/controllers/cart_controller.dart';
import 'modules/admin/admin_dashboard.dart';
import 'modules/super_admin/super_admin_dashboard.dart';
import 'modules/reports/viewer_reports_dashboard.dart';
import 'routing/app_routes.dart';
import 'routing/role_based_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Disable persistence to avoid stale cache issues
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX cart controller
    Get.put(CartController());

    return MaterialApp(
      title: 'Fruit POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.employeeDashboard: (context) => const PosHomeScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboard(),
        AppRoutes.superAdminDashboard: (context) => const SuperAdminDashboard(),
        AppRoutes.viewerDashboard: (context) => const ViewerReportsDashboard(),
      },
      home: const InactivityWrapper(
        child: AuthWrapper(),
      ),
    );
  }
}

/// Wrapper widget that listens to authentication state and routes accordingly.
/// Enforces: account status check, role-based redirection, shop assignment validation.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;

        // User is not authenticated, show login screen
        if (user == null) {
          return const LoginScreen();
        }

        // User is authenticated, fetch user data and navigate
        return FutureBuilder<UserModel>(
          future: _fetchUserData(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your dashboard...'),
                    ],
                  ),
                ),
              );
            }

            if (userSnapshot.hasError) {
              final error = userSnapshot.error;
              developer.log(
                'Error fetching user data from Firestore',
                name: 'AuthWrapper',
                error: error,
                stackTrace: userSnapshot.stackTrace,
              );

              // Determine error type
              bool isUserSpecificError = false;
              bool isAccountStatusError = false;
              String errorMessage =
                  error?.toString() ?? 'Unknown error occurred';

              if (error is FirebaseException) {
                errorMessage =
                    'Database error (${error.code}): ${error.message ?? 'Unknown'}';
              } else if (error is Exception) {
                final errorStr = error.toString().toLowerCase();
                if (errorStr.contains('user document not found') ||
                    errorStr.contains('user role is empty')) {
                  isUserSpecificError = true;
                } else if (errorStr.contains('account is inactive') ||
                    errorStr.contains('account has been suspended') ||
                    errorStr.contains('no shop assigned')) {
                  isAccountStatusError = true;
                }
              }

              // Sign out for user-specific and account status errors (logLogout + signOut)
              if (isUserSpecificError || isAccountStatusError) {
                AuthController().signOut();
                if (isAccountStatusError) {
                  // Show a message before returning to login
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.block,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Account Access Denied',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              errorMessage.replaceAll('Exception: ', ''),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () async {
                              await AuthController().signOut();
                              if (mounted) setState(() {});
                            },
                            child: const Text('Back to Login'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const LoginScreen();
              }

              // For database/infrastructure errors, show retry UI
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Database Connection Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          await AuthController().signOut();
                          if (mounted) setState(() {});
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!userSnapshot.hasData) {
              return const LoginScreen();
            }

            final UserModel userData = userSnapshot.data!;
            final String route = RoleBasedRouter.getInitialRoute(userData.role);

            // Navigate to the appropriate dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(route);
              }
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  /// Fetches user data from Firestore and validates account status.
  /// Returns UserModel if valid, throws appropriate exceptions on failure.
  /// Uses bootstrapFirstUser callable when inactive and no other active user exists.
  Future<UserModel> _fetchUserData(String userId) async {
    try {
      DocumentSnapshot userDoc;
      try {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          final result = await FirebaseFunctions.instance
              .httpsCallable('bootstrapFirstUser')
              .call<Map<String, dynamic>>();
          final data = result.data;
          if (data['activated'] == true) {
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Concurrent login restriction (optional advanced): if a remote
      // activeSessionId exists and does not match this device, treat as invalid.
      final remoteSessionId = data['activeSessionId'] as String?;
      final isActiveHere = await SessionManager.isCurrentDeviceActive(
        userId,
        remoteSessionId,
      );
      if (!isActiveHere) {
        throw Exception(
          'Your session has been closed because your account was used on another device.',
        );
      }

      UserModel user = UserModel.fromMap(data);

      // Check account status
      if (!user.isActive) {
        if (user.isSuspended) {
          throw Exception(
            'Your account has been suspended. Contact administrator.',
          );
        }
        // Bootstrap via callable: server activates this account if no other user is Active
        try {
          final result = await FirebaseFunctions.instance
              .httpsCallable('bootstrapFirstUser')
              .call<Map<String, dynamic>>();
          final data = result.data;
          if (data['activated'] == true) {
            developer.log(
              'Bootstrap: account activated (no other active users)',
              name: 'AuthWrapper',
            );
            user = user.copyWith(status: 'Active');
          } else {
            throw Exception('Your account is inactive. Contact administrator.');
          }
        } on FirebaseFunctionsException catch (e) {
          developer.log('Bootstrap callable error: ${e.code} ${e.message}', name: 'AuthWrapper');
          throw Exception('Your account is inactive. Contact administrator.');
        }
      }

      // Validate role exists
      if (user.role.isEmpty) {
        throw Exception('User role is empty');
      }

      // Validate shopId for non-SuperAdmin (canonical role)
      if (user.role != 'SuperAdmin' && user.shopId.isEmpty) {
        throw Exception('No shop assigned. Contact administrator.');
      }

      developer.log(
        'User loaded: ${user.name} (${user.role}) shop=${user.shopId}',
        name: 'AuthWrapper',
      );

      return user;
    } on FirebaseException catch (e) {
      developer.log(
        'Firestore error: code=${e.code}, message=${e.message}',
        name: '_fetchUserData',
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Error fetching user data',
        name: '_fetchUserData',
        error: e,
      );
      rethrow;
    }
  }
}
