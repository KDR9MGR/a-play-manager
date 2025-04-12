import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/features/auth/widgets/auth_widgets.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoginHeader(),
                    const SizedBox(height: 32),
                    _LoginFormContainer(),
                    const SizedBox(height: 24),
                    const LoginFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A container widget that handles the login form state internally
class _LoginFormContainer extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LoginFormContainer> createState() => _LoginFormContainerState();
}

class _LoginFormContainerState extends ConsumerState<_LoginFormContainer> {
  // We'll manage our own controllers directly
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } catch (e) {
        // Errors are handled by the AuthNotifier and shown via the AuthErrorMessage widget
        debugPrint('Login error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pass controllers directly to the login form
    return LoginForm(
      onLoginPressed: _handleLogin,
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
    );
  }
}
