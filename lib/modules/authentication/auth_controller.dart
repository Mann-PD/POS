import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer' as developer;
import '../../data/models/user_model.dart';

/// Controller for handling authentication operations.
/// Enforces: active status check, role-based redirection, no self-registration.
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Login with email and password.
  /// Returns UserModel if successful, throws exception on failure.
  /// Enforces: account must be Active, role must exist, shopId must exist (except super_admin).
  Future<UserModel> login(String email, String password) async {
    try {
      // Step 1: Authenticate with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final String userId = userCredential.user!.uid;

      // Step 2: Fetch user document from Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception(
          'User account not found. Please contact administrator.',
        );
      }

      final UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
      );

      // Step 3: Check account status (Active / Inactive / Suspended)
      if (!user.isActive) {
        await _auth.signOut();
        if (user.isSuspended) {
          throw Exception(
            'Your account has been suspended. Please contact administrator.',
          );
        }
        throw Exception(
          'Your account is inactive. Please contact administrator.',
        );
      }

      // Step 4: Validate role exists
      if (user.role.isEmpty) {
        await _auth.signOut();
        throw Exception('No role assigned. Please contact administrator.');
      }

      // Step 5: Validate shopId for non-Super Admin users (canonical role)
      if (user.role != 'Super Admin' && user.shopId.isEmpty) {
        await _auth.signOut();
        throw Exception('No shop assigned. Please contact administrator.');
      }

      developer.log(
        'Login successful: ${user.name} (${user.role}) - Shop: ${user.shopId}',
        name: 'AuthController',
      );

      return user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Fetch the current user's UserModel from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  /// Sign out - logs logout for audit then signs out
  Future<void> signOut() async {
    try {
      final logLogout = FirebaseFunctions.instance.httpsCallable('logLogout');
      await logLogout.call(<String, dynamic>{});
    } catch (_) {
      // Non-blocking; do not fail sign out if audit log fails
    }
    developer.log('User signed out', name: 'AuthController');
    await _auth.signOut();
  }
}
