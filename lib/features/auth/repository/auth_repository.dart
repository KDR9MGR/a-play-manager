import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:a_play_manage/core/models/user_model.dart';
import 'package:a_play_manage/core/errors/auth_exceptions.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Authentication methods
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw AuthException(message: 'An unexpected error occurred during sign in');
    }
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(displayName);
      
      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, displayName);
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Registration error: $e');
      throw AuthException(message: 'An unexpected error occurred during registration');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw AuthException(message: 'Failed to sign out');
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Reset password error: $e');
      throw AuthException(message: 'Failed to send password reset email');
    }
  }
  
  // User data methods
  
  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      final userModel = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: displayName,
        profileImageUrl: user.photoURL,
        isOrganizer: false, // Default to false, admin will set to true later
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: false,
      );
      
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    } catch (e) {
      debugPrint('Error creating user document: $e');
      throw AuthException(message: 'Failed to create user profile');
    }
  }
  
  // Get user document from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      throw AuthException(message: 'Failed to retrieve user data');
    }
  }
  
  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      throw AuthException(message: 'Failed to retrieve user');
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw AuthException(message: 'Failed to update profile');
    }
  }
} 