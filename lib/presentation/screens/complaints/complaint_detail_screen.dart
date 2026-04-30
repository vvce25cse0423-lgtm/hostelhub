// lib/presentation/screens/complaints/complaint_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../widgets/shimmer_loader.dart';

class ComplaintDetailScreen extends ConsumerWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintAsync = ref.watch(_complaintDetailProvider(complaintId));

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: complaintAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (complaint) {
          if (complaint == null) {
            return const Center(child: Text('Complaint not found'));
          }
          return _ComplaintDetailContent(complaint: complaint);
        },
      ),
    );
  }
}

class _ComplaintDetailContent extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintDetailContent({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Timeline
          _buildStatusTimeline(theme),
          const SizedBox(height: 24),

          // Complaint Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _CategoryBadge(category: complaint.category),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy').format(complaint.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(complaint.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(complaint.description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),

          // Complaint Image
          if (complaint.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: complaint.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (c, u) => const ShimmerLoader(height: 220),
                errorWidget: (c, u, e) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ],

          // Admin Note
          if (complaint.adminNote != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.message_text, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text('Admin Response',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(complaint.adminNote!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(ThemeData theme) {
    final statuses = [
      (AppConstants.complaintPending, 'Submitted', Iconsax.clock),
      (AppConstants.complaintInProgress, 'In Progress', Iconsax.refresh_circle),
      (AppConstants.complaintResolved, 'Resolved', Iconsax.tick_circle),
    ];

    int currentIndex = statuses.indexWhere((s) => s.$1 == complaint.status);

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final isCompleted = i <= currentIndex;
        final isCurrent = i == currentIndex;

        Color stepColor = isCompleted
            ? (isCurrent && complaint.status == AppConstants.complaintPending
                ? AppTheme.warningOrange
                : isCurrent && complaint.status == AppConstants.complaintInProgress
                    ? AppTheme.primaryBlue
                    : AppTheme.successGreen)
            : theme.colorScheme.outline.withOpacity(0.3);

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? stepColor
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.$3,
                      size: 18,
                      color: isCompleted ? Colors.white : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.$2,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted ? stepColor : theme.colorScheme.outline,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w400,
                      )),
                ],
              ),
              if (i < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < currentIndex
                        ? AppTheme.successGreen
                        : theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

final _complaintDetailProvider =
    FutureProvider.family<ComplaintModel?, String>((ref, id) async {
  final repo = ref.watch(complaintRepositoryProvider);
  final result = await repo.getComplaintById(id);
  return result.fold((_) => null, (c) => c);
});
