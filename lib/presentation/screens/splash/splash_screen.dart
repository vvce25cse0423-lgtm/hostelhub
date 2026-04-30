// lib/presentation/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.75, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final role =
          session.user.userMetadata?['role'] as String? ?? 'student';
      context.go(
          (role == 'admin' || role == 'warden')
              ? AppRoutes.adminDashboard
              : AppRoutes.studentDashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4D),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(scale: _scale.value, child: child),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/hostel_hub_logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryDark
                        ]),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(Icons.apartment_rounded,
                          color: Colors.white, size: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'HOSTEL ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3),
                  ),
                  TextSpan(
                    text: 'HUB',
                    style: TextStyle(
                        color: Color(0xFF00E5CC),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              const Text(
                'STAY  •  MANAGE  •  CONNECT',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(
                  color: Color(0xFF00E5CC), strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
