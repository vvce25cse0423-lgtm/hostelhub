// lib/presentation/screens/student/student_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    return authState.when(
      loading: () => const Scaffold(body: ShimmerLoader()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));
        return _DashboardBody(user: user);
      },
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final UserModel user;
  const _DashboardBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allocationAsync = ref.watch(_allocationProvider(user.id));
    final feeSummaryAsync = ref.watch(_feeSummaryProvider(user.id));
    final todayAttendanceAsync = ref.watch(_todayAttendanceProvider(user.id));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_allocationProvider);
          ref.invalidate(_feeSummaryProvider);
          ref.invalidate(_todayAttendanceProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ─── Header ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _greeting(),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            user.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'USN: ${user.usn ?? "N/A"}  •  ${DateFormat("EEE, MMM d").format(DateTime.now())}',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.notification, color: Colors.white),
                  onPressed: () => context.go(AppRoutes.notifications),
                ),
                IconButton(
                  icon: const Icon(Iconsax.user, color: Colors.white),
                  onPressed: () => context.go(AppRoutes.studentProfile),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ─── Today's Hostel Status ─────────────────────────────
                  todayAttendanceAsync.when(
                    loading: () => const ShimmerLoader(height: 80),
                    error: (_, __) => const SizedBox(),
                    data: (record) => _HostelStatusCard(record: record),
                  ),
                  const SizedBox(height: 16),

                  // ─── Fee Summary ───────────────────────────────────────
                  feeSummaryAsync.when(
                    loading: () => const ShimmerLoader(height: 90),
                    error: (_, __) => const SizedBox(),
                    data: (summary) => Row(
                      children: [
                        Expanded(child: _StatTile(
                          title: 'Pending Fees',
                          value: '₹${(summary?["pending"] ?? 0).toStringAsFixed(0)}',
                          icon: Iconsax.wallet,
                          color: AppTheme.warningOrange,
                          onTap: () => context.go(AppRoutes.fees),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(
                          title: 'Overdue',
                          value: '₹${(summary?["overdue"] ?? 0).toStringAsFixed(0)}',
                          icon: Iconsax.warning_2,
                          color: AppTheme.errorRed,
                          onTap: () => context.go(AppRoutes.fees),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Quick Actions ─────────────────────────────────────
                  Text('Quick Actions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _QuickActionsGrid(),
                  const SizedBox(height: 16),

                  // ─── My Room ───────────────────────────────────────────
                  Text('My Room', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  allocationAsync.when(
                    loading: () => const ShimmerLoader(height: 100),
                    error: (_, __) => _noRoomCard(context, theme),
                    data: (alloc) => alloc == null
                        ? _noRoomCard(context, theme)
                        : _MyRoomCard(alloc: alloc),
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning! 🌅';
    if (h < 17) return 'Good Afternoon! ☀️';
    return 'Good Evening! 🌙';
  }

  Widget _noRoomCard(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Iconsax.building, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 10),
            Text('No Room Assigned', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Browse rooms and request allocation',
                style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.rooms),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Browse Rooms'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostelStatusCard extends StatelessWidget {
  final Map<String, dynamic>? record;
  const _HostelStatusCard({this.record});

  @override
  Widget build(BuildContext context) {
    final isPresent = record != null && record!['status'] == 'present';
    final hasRecord = record != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPresent
            ? AppTheme.successGreen.withOpacity(0.1)
            : hasRecord
                ? AppTheme.errorRed.withOpacity(0.1)
                : AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent
              ? AppTheme.successGreen.withOpacity(0.3)
              : hasRecord
                  ? AppTheme.errorRed.withOpacity(0.3)
                  : AppTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPresent ? Icons.home_rounded : hasRecord ? Icons.exit_to_app : Icons.help_outline,
            color: isPresent
                ? AppTheme.successGreen
                : hasRecord ? AppTheme.errorRed : AppTheme.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !hasRecord
                      ? 'Today\'s status not marked yet'
                      : isPresent
                          ? 'You are Present in Hostel'
                          : 'You are Absent Today',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isPresent
                        ? AppTheme.successGreen
                        : hasRecord ? AppTheme.errorRed : AppTheme.primaryBlue,
                  ),
                ),
                Text('Marked by Warden/Admin',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Iconsax.message_add, 'Raise Complaint', AppRoutes.complaints, AppTheme.warningOrange),
      (Iconsax.building, 'View Rooms', AppRoutes.rooms, AppTheme.primaryBlue),
      (Iconsax.receipt, 'Pay Fees', AppRoutes.fees, AppTheme.successGreen),
      (Iconsax.clock, 'Attendance', AppRoutes.attendance, AppTheme.infoBlue),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: actions.map((a) => GestureDetector(
        onTap: () => context.go(a.$3),
        child: Container(
          decoration: BoxDecoration(
            color: a.$4.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.$4.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.$1, color: a.$4, size: 22),
              const SizedBox(height: 6),
              Text(a.$2,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: a.$4, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatTile({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(title, style: TextStyle(color: color, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRoomCard extends StatelessWidget {
  final AllocationModel alloc;
  const _MyRoomCard({required this.alloc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final room = alloc.room!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.building, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${room.roomNumber}', style: theme.textTheme.titleMedium),
                  Text('Floor ${room.floor} • ${room.type.toUpperCase()}', style: theme.textTheme.bodySmall),
                  Text('${room.occupancy}/${room.capacity} occupied', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (room.monthlyRent != null)
              Text('₹${room.monthlyRent!.toStringAsFixed(0)}/mo',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _allocationProvider = FutureProvider.family<AllocationModel?, String>((ref, studentId) async {
  final result = await ref.watch(roomRepositoryProvider).getStudentAllocation(studentId);
  return result.fold((_) => null, (a) => a);
});

final _feeSummaryProvider = FutureProvider.family<Map<String, double>?, String>((ref, studentId) async {
  final result = await ref.watch(feeRepositoryProvider).getFeeSummary(studentId);
  return result.fold((_) => null, (s) => s);
});

final _todayAttendanceProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, studentId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await client.from('attendance').select().eq('student_id', studentId).eq('date', today).maybeSingle();
    return data as Map<String, dynamic>?;
  } catch (_) { return null; }
});
