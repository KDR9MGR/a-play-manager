import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/auth/repository/auth_repository.dart';
import 'package:a_play_manage/core/errors/auth_exceptions.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';

/// State for password reset functionality
class PasswordResetState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  const PasswordResetState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  PasswordResetState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return PasswordResetState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

/// Notifier for password reset functionality
class PasswordResetNotifier extends StateNotifier<PasswordResetState> {
  final AuthRepository _authRepository;

  PasswordResetNotifier(this._authRepository) : super(const PasswordResetState());

  /// Request a password reset email
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(
        isLoading: true, 
        error: null,
        isSuccess: false,
      );
      
      await _authRepository.resetPassword(email);
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        isSuccess: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send password reset email',
        isSuccess: false,
      );
    }
  }

  /// Clear the state
  void clearState() {
    state = const PasswordResetState();
  }
}

/// Provider for password reset functionality
final passwordResetProvider = StateNotifierProvider<PasswordResetNotifier, PasswordResetState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return PasswordResetNotifier(authRepository);
}); 