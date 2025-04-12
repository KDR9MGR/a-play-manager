import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/auth/repository/auth_repository.dart';
import 'package:a_play_manage/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:a_play_manage/core/errors/auth_exceptions.dart';

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Current user provider - provides the UserModel of the current authenticated user
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges.map((user) {
    if (user != null) {
      return authRepository.getUserData(user.uid);
    }
    return null;
  }).asyncMap((userFuture) async => userFuture);
});

// Auth state provider - provides a simple boolean indicating if user is logged in
final authStateProvider = StreamProvider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges.map((user) => user != null);
});

// Organizer status provider - provides if current user is an organizer
final isOrganizerProvider = Provider<bool>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);
  return userAsyncValue.when(
    data: (user) => user?.isOrganizer ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// User verification status provider - provides if current user is verified
final isVerifiedProvider = Provider<bool>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);
  return userAsyncValue.when(
    data: (user) => user?.isVerified ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Auth State class to handle authentication state
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Auth notifier for handling authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState()) {
    // Initialize state by listening to auth changes
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        );
      }
    });
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final userCredential = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(
        user: userCredential.user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        isAuthenticated: false,
      );
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
        isAuthenticated: false,
      );
      rethrow;
    }
  }

  /// Sign up with email, password and display name
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final userCredential = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      state = state.copyWith(
        user: userCredential.user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.message,
        isAuthenticated: false,
      );
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
        isAuthenticated: false,
      );
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.signOut();
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out',
      );
      rethrow;
    }
  }

  /// Request a password reset email
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authRepository.resetPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send password reset email',
      );
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
}); 