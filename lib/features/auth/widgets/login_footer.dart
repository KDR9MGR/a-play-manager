import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildRegisterOption(theme, context),
        const SizedBox(height: 16),
        _buildGuestOption(theme, context),
      ],
    );
  }
  
  Widget _buildRegisterOption(ThemeData theme, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        TextButton(
          onPressed: () => context.pushReplacement('/register'),
          child: const Text('Sign Up'),
        ),
      ],
    );
  }
  
  Widget _buildGuestOption(ThemeData theme, BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/events'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        'Continue as Guest',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
} 