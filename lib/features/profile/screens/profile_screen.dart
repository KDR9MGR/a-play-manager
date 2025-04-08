import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:a_play_manage/core/models/user_model.dart';
import 'package:a_play_manage/features/auth/providers/auth_provider.dart';
import 'package:a_play_manage/shared/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          //Back to dashboard
          onPressed: () => context.go('/dashboard'),

        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found.'),
            );
          }
          
          return _buildProfileContent(context, user, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildProfileContent(BuildContext context, UserModel user, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage: user.profileImageUrl != null 
                ? NetworkImage(user.profileImageUrl!) 
                : null,
            child: user.profileImageUrl == null 
                ? Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            user.name,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Organiser badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: user.isOrganizer
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.isOrganizer ? 'Organizer' : 'Regular User',
              style: TextStyle(
                color: user.isOrganizer ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Info Cards
          _buildInfoCard(
            context,
            title: 'Contact Information',
            items: [
              InfoItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: user.email,
              ),
              InfoItem(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: user.phoneNumber ?? 'Not added',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            context,
            title: 'Account Information',
            items: [
              InfoItem(
                icon: Icons.calendar_today,
                title: 'Member Since',
                value: '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
              ),
              InfoItem(
                icon: Icons.badge_outlined,
                title: 'Account Type',
                value: user.isOrganizer ? 'Organizer' : 'Regular User',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            context,
            title: 'About Me',
            items: [
              InfoItem(
                icon: Icons.info_outline,
                title: 'Bio',
                value: user.bio ?? 'No bio added yet.',
                isMultiline: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Edit Profile Button
          CustomButton(
            text: 'Edit Profile',
            onPressed: () => context.pushNamed('edit-profile'),
            icon: Icons.edit,
            isOutlined: true,
          ),
          const SizedBox(height: 16),
          
          // Sign Out Button
          CustomButton(
            text: 'Sign Out',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
            icon: Icons.logout,
            isOutlined: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<InfoItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...items.map((item) => _buildInfoItem(context, item)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(BuildContext context, InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: item.isMultiline 
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            item.icon,
            size: 20,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoItem {
  final IconData icon;
  final String title;
  final String value;
  final bool isMultiline;
  
  InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    this.isMultiline = false,
  });
} 