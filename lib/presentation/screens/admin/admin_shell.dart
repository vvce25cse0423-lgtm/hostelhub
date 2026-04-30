// lib/presentation/screens/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/router/app_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  int _getIndex(String location) {
    if (location.startsWith('/admin/rooms')) return 1;
    if (location.startsWith('/admin/students')) return 2;
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
              context.go(AppRoutes.adminDashboard);
            case 1:
              context.go(AppRoutes.adminRooms);
            case 2:
              context.go(AppRoutes.adminStudents);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_15),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.building),
            selectedIcon: Icon(Iconsax.building_35),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.people),
            selectedIcon: Icon(Iconsax.people5),
            label: 'Students',
          ),
        ],
      ),
    );
  }
}
