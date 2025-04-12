import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/features/auth/widgets/auth_error_message.dart';
import 'package:a_play_manage/shared/widgets/custom_text_field.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onLoginPressed;
  final Function(GlobalKey<FormState>)? onFormKeyCreated;
  final Function(TextEditingController)? onEmailControllerCreated;
  final Function(TextEditingController)? onPasswordControllerCreated;
  
  // Optional controllers that can be passed directly
  final GlobalKey<FormState>? formKey;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;

  const LoginForm({
    super.key,
    required this.onLoginPressed,
    this.onFormKeyCreated,
    this.onEmailControllerCreated,
    this.onPasswordControllerCreated,
    this.formKey,
    this.emailController,
    this.passwordController,
  });

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _ownsControllers = false;

  @override
  void initState() {
    super.initState();
    // Use provided controllers or create our own
    _formKey = widget.formKey ?? GlobalKey<FormState>();
    _emailController = widget.emailController ?? TextEditingController();
    _passwordController = widget.passwordController ?? TextEditingController();
    _ownsControllers = widget.emailController == null || widget.passwordController == null;
    
    // Share controllers with parent if needed
    widget.onFormKeyCreated?.call(_formKey);
    widget.onEmailControllerCreated?.call(_emailController);
    widget.onPasswordControllerCreated?.call(_passwordController);
  }

  @override
  void dispose() {
    // Only dispose controllers we created
    if (_ownsControllers) {
      _emailController.dispose();
      _passwordController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          CustomTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            onSuffixIconPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Error message
          AuthErrorMessage(errorMessage: authState.error?.toString()),

          // Login button
          CustomButton(
            text: 'Sign In',
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onLoginPressed();
              }
            },
            isLoading: authState.isLoading,
            icon: Icons.login,
          ),
        ],
      ),
    );
  }
} 