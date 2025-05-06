import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../data/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    // Show loading if auth state is loading
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Show error if auth state has error
    if (authState.error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: ${authState.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    // Check if user is verified
    final user = authState.user;
    if (user == null) {
      // Redirect to login should happen via router, but add fallback
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login to access the dashboard',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Check if user is verified
    final userState = ref.watch(currentUserProvider);
    
    return userState.when(
      data: (userModel) {
        print(userModel!.email);
        if (!userModel.isVerified) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.shield_cross,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Not Verified',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait for admin verification to access the dashboard.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Iconsax.arrow_left),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/events/add'),
            icon: const Icon(Iconsax.add_circle),
            label: const Text('Add Event'),
          ),
          body: SafeArea(
            child: dashboardAsync.when(
              data: (dashboard) => SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _WelcomeHeader(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildStatCards(dashboard),
                    const SizedBox(height: 24),
                    _buildCharts(dashboard),
                    const SizedBox(height: 24),
                    _buildRecentActivities(dashboard),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading dashboard data: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            label: 'My Events',
            icon: Iconsax.calendar_1,
            onTap: () => context.push('/events'),
          ),
          _QuickActionButton(
            label: 'Add Event',
            icon: Iconsax.add_circle,
            onTap: () => context.push('/events/add'),
          ),
          _QuickActionButton(
            label: 'Profile',
            icon: Iconsax.profile_circle,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(DashboardData dashboard) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        _StatCard(
          title: 'Total Events',
          value: dashboard.totalEvents.toString(),
          icon: Iconsax.calendar_2,
          color: const Color(0xFF6C63FF),
          animation: _animationController,
        ),
        _StatCard(
          title: 'Total Attendees',
          value: NumberFormat.compact().format(dashboard.totalAttendees),
          icon: Iconsax.people,
          color: const Color(0xFFFF6B6B),
          animation: _animationController,
        ),
      ],
    );
  }

  Widget _buildCharts(DashboardData dashboard) {
    final total = dashboard.revenueDistribution.values.fold<double>(0, (a, b) => a + b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
          child: Text(
            'Analytics Overview',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event Categories',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                      
                        centerSpaceRadius: 60,
                        
                        sections: dashboard.revenueDistribution.entries.map((entry) {
                          final percentage = total > 0 ? (entry.value / total * 100) : 0;
                          return PieChartSectionData(
                            value: entry.value,
                            title: percentage < 5 ? '' : '${percentage.toStringAsFixed(0)}%',
                            color: _getCategoryColor(entry.key),
                            radius: 85,
                            titleStyle: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            showTitle: false,
                          );
                        }).toList(),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildChartLegend(dashboard),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(DashboardData dashboard) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dashboard.revenueDistribution.entries.map((entry) {
        final total = dashboard.revenueDistribution.values.fold<double>(0, (a, b) => a + b);
        final percentage = total > 0 ? (entry.value / total * 100) : 0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return const Color(0xFF6C63FF);
      case 'music':
        return const Color(0xFFFF6B6B);
      case 'theater':
        return const Color(0xFFFFBE0B);
      default:
        return const Color(0xFF4ECDC4);
    }
  }

  Widget _buildRecentActivities(DashboardData dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activities',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/events'),
              icon: const Icon(Iconsax.arrow_right_3),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboard.recentActivities.length,
          itemBuilder: (context, index) {
            final activity = dashboard.recentActivities[index];
            return _ActivityCard(
              title: activity.title,
              subtitle: activity.subtitle,
              time: activity.time,
              icon: Iconsax.calendar_tick,
              animation: _animationController,
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Event Manager',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            context.push('/profile');
          },
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Iconsax.user,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AnimationController animation;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final AnimationController animation;

  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 