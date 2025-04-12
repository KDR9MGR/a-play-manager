import 'package:a_play_manage/features/auth/data/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:a_play_manage/features/auth/screens/login_screen.dart';
import 'package:a_play_manage/features/auth/screens/register_screen.dart';
import 'package:a_play_manage/features/auth/screens/forgot_password_screen.dart';
import 'package:a_play_manage/features/dashboard/presentation/dashboard_screen.dart';
import 'package:a_play_manage/features/events/screens/events_screen.dart';
import 'package:a_play_manage/features/events/screens/add_event_screen.dart';
import 'package:a_play_manage/features/events/screens/edit_event_screen.dart';
import 'package:a_play_manage/features/events/screens/event_details_screen.dart';
import 'package:a_play_manage/features/profile/screens/profile_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true, // Enable debug logging
    redirect: (context, state) {
      

      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';
      final isForgotPassword = state.uri.toString() == '/forgot-password';

      // Allow access to auth-related pages when not logged in
      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering || isForgotPassword) {
          return null;
        }
        debugPrint('Redirecting to login');
        return '/login';
      }

      // Redirect to dashboard if trying to access auth pages while logged in
      if (isLoggedIn && (isLoggingIn || isRegistering || isForgotPassword)) {
        debugPrint('Redirecting to dashboard');
        return '/dashboard';
      }

      debugPrint('No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          if (authState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
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