import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maps exceptions to user-facing copy without exposing infrastructure details.
class UserSafeErrorMapper {
  UserSafeErrorMapper._();

  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      return _authMessage(error);
    }
    if (error is FirebaseFunctionsException) {
      return _functionsMessage(error);
    }
    if (error is FirebaseException) {
      return _firebaseMessage(error);
    }
    if (error is Exception) {
      final raw = error.toString();
      final stripped = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
      if (_isUserFacingBusinessMessage(stripped)) {
        return stripped;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  static String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  static String _functionsMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'permission-denied':
      case 'unauthenticated':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested resource was not found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'invalid-argument':
        return 'Invalid request. Check your input and try again.';
      case 'resource-exhausted':
        return 'Service is busy. Please try again shortly.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return 'Operation failed. Please try again.';
    }
  }

  static String _firebaseMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to access this data.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Unable to reach the server. Check your connection.';
      case 'not-found':
        return 'Requested data was not found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'failed-precondition':
        return 'This action cannot be completed right now.';
      case 'resource-exhausted':
        return 'Too many requests. Please wait and try again.';
      case 'unauthenticated':
        return 'Please sign in again.';
      case 'cancelled':
        return 'Request was cancelled.';
      default:
        return 'A database error occurred. Please try again.';
    }
  }

  /// Business exceptions thrown intentionally (account status, validation).
  static bool _isUserFacingBusinessMessage(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'account',
      'contact administrator',
      'shop assigned',
      'role',
      'session',
      'suspended',
      'inactive',
      'not found',
      'invalid',
      'permission',
    ];
    return markers.any(lower.contains) && !lower.contains('firebase');
  }
}
