import 'package:firebase_auth/firebase_auth.dart';

/// Custom exception class for handling authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException({
    required this.message,
    this.code,
  });

  /// Create AuthException from FirebaseAuthException
  factory AuthException.fromFirebaseAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        message = 'Too many requests. Try again later.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }

    return AuthException(
      message: message,
      code: e.code,
    );
  }

  @override
  String toString() => 'AuthException: $message (code: $code)';
} 