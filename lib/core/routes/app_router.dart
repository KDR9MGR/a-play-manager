import 'package:a_play_manage/features/events/screens/add_event_screen.dart';
import 'package:a_play_manage/features/events/screens/edit_event_screen.dart';
import 'package:a_play_manage/features/events/screens/event_details_screen.dart';
import 'package:a_play_manage/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/events/presentation/events_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Handle loading state
      if (authState.isLoading || authState.hasError) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          // Show loading indicator while checking auth state
          if (authState.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Show error if auth state has error
          if (authState.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${authState.error}'),
              ),
            );
          }
          
          return const DashboardScreen();
        },
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddEventScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) => EditEventScreen(
              eventId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'details/:id',
            builder: (context, state) => EventDetailsScreen(
              eventId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}); 