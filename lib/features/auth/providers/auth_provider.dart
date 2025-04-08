import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/auth/repository/auth_repository.dart';
import 'package:a_play_manage/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth repository provider
final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// Current user provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges.map((user) {
    if (user != null) {
      return authRepository.getUserData(user.uid);
    }
    return null;
  }).asyncMap((userFuture) async => userFuture);
});

// Auth state provider
final authStateProvider = StreamProvider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges.map((user) {
    if (user != null) {
      return true;
    }
    return false;
  });
});

// Organizer status provider
final isOrganizerProvider = Provider<bool>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);
  return userAsyncValue.when(
    data: (user) => user?.isOrganizer ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Auth repository
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return UserModel.fromFirestore(userDoc);
    }
    return null;
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return null;
      }
      
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Sign in
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        return getUserData(userCredential.user!.uid);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed');
    }
  }

  // Register
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Create user document
        final newUser = UserModel(
          id: user.uid,
          name: name,
          email: email,
          isOrganizer: isOrganizer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
            
        return newUser;
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Password reset failed');
    }
  }

  // Update user
  Future<UserModel?> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
      
      return user;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return null;
    }
  }
}

// Auth state
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      
      state = state.copyWith(isLoading: false, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        isOrganizer: isOrganizer,
      );
      
      state = state.copyWith(isLoading: false, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepository.signOut();
      state = state.copyWith(isLoading: false, user: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out',
      );
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepository.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> updateUserProfile({
    required String name,
    String? phoneNumber,
    String? bio,
    String? profileImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          name: name,
          phoneNumber: phoneNumber,
          bio: bio,
          profileImageUrl: profileImageUrl,
          updatedAt: DateTime.now(),
        );
        
        final result = await _authRepository.updateUser(updatedUser);
        
        if (result != null) {
          state = state.copyWith(isLoading: false, user: result);
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to update profile',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating profile: $e',
      );
    }
  }
}

// Auth exception
class AuthException implements Exception {
  final String message;
  
  AuthException(this.message);
} 