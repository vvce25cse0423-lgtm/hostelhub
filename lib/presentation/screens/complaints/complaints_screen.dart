// lib/presentation/screens/complaints/complaints_screen.dart
// Complaint list screen with real-time updates

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';

class ComplaintsScreen extends ConsumerStatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  ConsumerState<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends ConsumerState<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statuses = ['all', 'pending', 'in_progress', 'resolved'];
  final _statusLabels = ['All', 'Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _statusLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses.map((status) {
          return _ComplaintsList(
            studentId: user?.id,
            status: status == 'all' ? null : status,
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('${AppRoutes.complaints}/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Complaint'),
      ),
    );
  }
}

class _ComplaintsList extends ConsumerWidget {
  final String? studentId;
  final String? status;

  const _ComplaintsList({this.studentId, this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(_complaintsProvider((
      studentId: studentId,
      status: status,
    )));

    return complaintsAsync.when(
      loading: () => const ShimmerLoader(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (complaints) {
        if (complaints.isEmpty) {
          return EmptyState(
            icon: Iconsax.message_minus,
            title: 'No Complaints',
            subtitle: status == null
                ? 'You haven\'t raised any complaints yet'
                : 'No ${status!.replaceAll('_', ' ')} complaints',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_complaintsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, i) =>
                _ComplaintCard(complaint: complaints[i])
                    .animate()
                    .fadeIn(delay: (i * 50).ms),
          ),
        );
      },
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('${AppRoutes.complaints}/${complaint.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CategoryChip(category: complaint.category),
                  const Spacer(),
                  _StatusBadge(status: complaint.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                complaint.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                complaint.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Iconsax.clock, size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(complaint.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                  if (complaint.imageUrl != null) ...[
                    const Spacer(),
                    Icon(Iconsax.image, size: 12, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text('Image attached',
                        style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case AppConstants.complaintPending:
        color = AppTheme.warningOrange;
        label = 'Pending';
        icon = Iconsax.clock;
      case AppConstants.complaintInProgress:
        color = AppTheme.primaryBlue;
        label = 'In Progress';
        icon = Iconsax.refresh_circle;
      case AppConstants.complaintResolved:
        color = AppTheme.successGreen;
        label = 'Resolved';
        icon = Iconsax.tick_circle;
      default:
        color = Colors.grey;
        label = status;
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
typedef _ComplaintsArgs = ({String? studentId, String? status});

final _complaintsProvider =
    FutureProvider.family<List<ComplaintModel>, _ComplaintsArgs>(
        (ref, args) async {
  final repo = ref.watch(complaintRepositoryProvider);
  final result = await repo.getComplaints(
    studentId: args.studentId,
    status: args.status,
  );
  return result.fold((_) => [], (list) => list);
});
