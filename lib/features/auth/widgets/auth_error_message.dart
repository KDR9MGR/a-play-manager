import 'package:flutter/material.dart';

class AuthErrorMessage extends StatelessWidget {
  final String? errorMessage;

  const AuthErrorMessage({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
} 