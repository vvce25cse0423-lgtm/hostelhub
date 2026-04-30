// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/supabase_client.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/student/student_shell.dart';
import '../../presentation/screens/student/student_dashboard_screen.dart';
import '../../presentation/screens/student/profile_screen.dart';
import '../../presentation/screens/admin/admin_shell.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_rooms_screen.dart';
import '../../presentation/screens/rooms/room_list_screen.dart';
import '../../presentation/screens/rooms/room_detail_screen.dart';
import '../../presentation/screens/complaints/complaints_screen.dart';
import '../../presentation/screens/complaints/complaint_detail_screen.dart';
import '../../presentation/screens/complaints/create_complaint_screen.dart';
import '../../presentation/screens/attendance/attendance_screen.dart';
import '../../presentation/screens/fees/fees_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';

part 'app_router.g.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';
  static const rooms = '/student/rooms';
  static const complaints = '/student/complaints';
  static const attendance = '/student/attendance';
  static const fees = '/student/fees';
  static const notifications = '/student/notifications';
  static const adminDashboard = '/admin/dashboard';
  static const adminRooms = '/admin/rooms';
  static const adminStudents = '/admin/students';
  static const adminComplaints = '/admin/complaints';
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // Student Shell
      ShellRoute(
        builder: (_, __, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.studentDashboard,
            builder: (_, __) => const StudentDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.rooms,
            builder: (_, __) => const RoomListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    RoomDetailScreen(roomId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.complaints,
            builder: (_, __) => const ComplaintsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CreateComplaintScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ComplaintDetailScreen(
                    complaintId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (_, __) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.fees,
            builder: (_, __) => const FeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.studentProfile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Admin Shell
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminRooms,
            builder: (_, __) => const AdminRoomsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminStudents,
            builder: (_, __) => const AdminStudentsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.bodyLarge),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
}
