import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/shared/widgets/custom_app_bar.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';
import 'package:a_play_manage/shared/widgets/custom_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userAsync = ref.read(currentUserProvider);
    
    userAsync.whenData((user) {
      if (user != null) {
        _nameController.text = user.name;
        if (user.phoneNumber != null) {
          _phoneController.text = user.phoneNumber!;
        }
        if (user.bio != null) {
          _bioController.text = user.bio!;
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      await authRepository.updateProfile(
        uid: currentUser.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        bio: _bioController.text.trim().isNotEmpty 
            ? _bioController.text.trim() 
            : null,
      );
      
      setState(() {
        _successMessage = 'Profile updated successfully!';
        _isLoading = false;
      });
      
      // Refresh user data
      ref.invalidate(currentUserProvider);
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone Number
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter your phone number (optional)',
                controller: _phoneController,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Bio
              CustomTextField(
                label: 'Bio',
                hint: 'Tell us about yourself (optional)',
                controller: _bioController,
                prefixIcon: Icons.info_outline,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Success message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Save button
              CustomButton(
                text: 'Save Changes',
                onPressed: _updateProfile,
                isLoading: _isLoading,
                icon: Icons.save,
              ),
              const SizedBox(height: 16),
              
              // Cancel button
              CustomButton(
                text: 'Cancel',
                onPressed: () => context.pop(),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 