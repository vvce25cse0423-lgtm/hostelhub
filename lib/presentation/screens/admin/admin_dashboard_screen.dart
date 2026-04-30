// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final roomStatsAsync = ref.watch(_adminRoomStatsProvider);
    final complaintStatsAsync = ref.watch(_adminComplaintStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_adminRoomStatsProvider);
          ref.invalidate(_adminComplaintStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Welcome back, ${user?.name ?? "Admin"}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Iconsax.logout, color: Colors.white),
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Room Overview', style: theme.textTheme.titleMedium)
                      .animate().fadeIn(),
                  const SizedBox(height: 12),
                  roomStatsAsync.when(
                    loading: () => const ShimmerLoader(height: 100),
                    error: (_, __) => const SizedBox(),
                    data: (stats) => _RoomStatsGrid(stats: stats ?? {}),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),
                  Text('Complaints Overview',
                          style: theme.textTheme.titleMedium)
                      .animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),
                  complaintStatsAsync.when(
                    loading: () => const ShimmerLoader(height: 200),
                    error: (_, __) => const SizedBox(),
                    data: (stats) => _ComplaintStatsCard(stats: stats ?? {}),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  Text('Quick Actions', style: theme.textTheme.titleMedium)
                      .animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 12),
                  const _AdminQuickActions().animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomStatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _RoomStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', stats['total'] ?? 0, Iconsax.building, AppTheme.primaryBlue),
      ('Available', stats['available'] ?? 0, Iconsax.tick_circle, AppTheme.successGreen),
      ('Full', stats['full'] ?? 0, Iconsax.close_circle, AppTheme.errorRed),
      ('Maintenance', stats['maintenance'] ?? 0, Iconsax.setting_2, AppTheme.warningOrange),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.$4.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.$4.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(item.$3, color: item.$4, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$2.toString(),
                      style: TextStyle(
                          color: item.$4,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  Text(item.$1,
                      style: TextStyle(color: item.$4, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComplaintStatsCard extends StatelessWidget {
  final Map<String, int> stats;
  const _ComplaintStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pending = stats['pending'] ?? 0;
    final inProgress = stats['in_progress'] ?? 0;
    final resolved = stats['resolved'] ?? 0;
    final total = pending + inProgress + resolved;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (total > 0)
              SizedBox(
                height: 160,
                child: PieChart(PieChartData(
                  sections: [
                    if (pending > 0)
                      PieChartSectionData(
                        color: AppTheme.warningOrange,
                        value: pending.toDouble(),
                        title: '$pending',
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        radius: 60,
                      ),
                    if (inProgress > 0)
                      PieChartSectionData(
                        color: AppTheme.primaryBlue,
                        value: inProgress.toDouble(),
                        title: '$inProgress',
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        radius: 60,
                      ),
                    if (resolved > 0)
                      PieChartSectionData(
                        color: AppTheme.successGreen,
                        value: resolved.toDouble(),
                        title: '$resolved',
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        radius: 60,
                      ),
                  ],
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                )),
              )
            else
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No complaints yet'),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Legend(color: AppTheme.warningOrange,
                    label: 'Pending', count: pending),
                _Legend(color: AppTheme.primaryBlue,
                    label: 'In Progress', count: inProgress),
                _Legend(color: AppTheme.successGreen,
                    label: 'Resolved', count: resolved),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ($count)',
            style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _AdminQuickActions extends StatelessWidget {
  const _AdminQuickActions();

  @override
  Widget build(BuildContext context) {
    // FIX: replaced Iconsax.building_add (doesn't exist) with Iconsax.building_3
    final actions = [
      (Iconsax.building_3, 'Manage Rooms', AppRoutes.adminRooms, AppTheme.primaryBlue),
      (Iconsax.people, 'Manage Students', AppRoutes.adminStudents, AppTheme.successGreen),
      (Iconsax.message, 'View Complaints', AppRoutes.complaints, AppTheme.warningOrange),
    ];

    return Column(
      children: actions
          .map((action) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: action.$4.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.$1, color: action.$4, size: 20),
                  ),
                  title: Text(action.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(action.$3),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _adminRoomStatsProvider = FutureProvider<Map<String, int>?>((ref) async {
  final result = await ref.watch(roomRepositoryProvider).getRoomStats();
  return result.fold((_) => null, (s) => s);
});

final _adminComplaintStatsProvider =
    FutureProvider<Map<String, int>?>((ref) async {
  final repo = ref.watch(complaintRepositoryProvider);
  final result = await repo.getComplaints();
  return result.fold((_) => null, (complaints) => {
        'pending': complaints.where((c) => c.isPending).length,
        'in_progress': complaints.where((c) => c.isInProgress).length,
        'resolved': complaints.where((c) => c.isResolved).length,
      });
});
