// lib/presentation/screens/student/student_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  int _getIndex(String location) {
    if (location.startsWith('/student/rooms')) return 1;
    if (location.startsWith('/student/complaints')) return 2;
    if (location.startsWith('/student/attendance')) return 3;
    if (location.startsWith('/student/fees')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.studentDashboard);
            case 1:
              context.go(AppRoutes.rooms);
            case 2:
              context.go(AppRoutes.complaints);
            case 3:
              context.go(AppRoutes.attendance);
            case 4:
              context.go(AppRoutes.fees);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_15),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.building),
            selectedIcon: Icon(Iconsax.building_35),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.message),
            selectedIcon: Icon(Iconsax.message5),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.clock),
            selectedIcon: Icon(Iconsax.clock5),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.wallet),
            selectedIcon: Icon(Iconsax.wallet_15),
            label: 'Fees',
          ),
        ],
      ),
    );
  }
}
