// lib/presentation/screens/rooms/room_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/app_snackbar.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(_roomDetailProvider(roomId));
    final occupantsAsync = ref.watch(_occupantsProvider(roomId));
    final user = ref.watch(authNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Room Details')),
      body: roomAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) {
            return const Center(child: Text('Room not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomInfoCard(room: room),
                const SizedBox(height: 16),

                // Request to occupy button for students
                if (user != null && !user.isAdmin && room.isAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _requestRoom(context, ref, room, user),
                      icon: const Icon(Icons.bedroom_parent_outlined),
                      label: const Text('Request This Room'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                if (user != null && !user.isAdmin && !room.isAvailable)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.errorRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, color: AppTheme.errorRed),
                        const SizedBox(width: 8),
                        Text('Room is not available',
                            style: TextStyle(color: AppTheme.errorRed)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),
                Text('Current Occupants',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                occupantsAsync.when(
                  loading: () => const ShimmerLoader(height: 80),
                  error: (_, __) => const SizedBox(),
                  data: (occupants) => occupants.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('No students assigned yet',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        )
                      : Column(
                          children: occupants
                              .map((a) => _OccupantTile(alloc: a))
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestRoom(BuildContext context, WidgetRef ref,
      RoomModel room, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Room ${room.roomNumber}?'),
        content: Text(
            'Floor ${room.floor} • ${room.type} • ${room.availableSlots} slot(s) available\n\nYour request will be sent to the admin for approval.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Request')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Submit as a complaint/request to admin
    final client = ref.read(supabaseClientProvider);
    try {
      await client.from('complaints').insert({
        'student_id': user.id,
        'title': 'Room Allocation Request — Room ${room.roomNumber}',
        'description':
            'Student is requesting to be allocated Room ${room.roomNumber} (Floor ${room.floor}, ${room.type}). Please process this request.',
        'category': 'other',
        'status': 'pending',
      });
      if (context.mounted) {
        AppSnackbar.showSuccess(context,
            'Request sent! Admin will allocate Room ${room.roomNumber} to you.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.showError(context, 'Error: $e');
    }
  }
}

class _RoomInfoCard extends StatelessWidget {
  final RoomModel room;
  const _RoomInfoCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor = room.status == 'available'
        ? AppTheme.successGreen
        : room.status == 'full'
            ? AppTheme.errorRed
            : AppTheme.warningOrange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.building_4,
                    color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room ${room.roomNumber}',
                        style: theme.textTheme.headlineSmall),
                    Text('Floor ${room.floor} • ${room.type.toUpperCase()}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(room.status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _InfoRow(icon: Iconsax.people, label: 'Capacity', value: '${room.capacity} beds'),
            const SizedBox(height: 10),
            _InfoRow(icon: Iconsax.user, label: 'Occupied', value: '${room.occupancy} students'),
            const SizedBox(height: 10),
            _InfoRow(icon: Iconsax.home, label: 'Available', value: '${room.availableSlots} beds free'),
            if (room.monthlyRent != null) ...[
              const SizedBox(height: 10),
              _InfoRow(icon: Iconsax.money, label: 'Monthly Rent',
                  value: '₹${room.monthlyRent!.toStringAsFixed(0)}'),
            ],
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: room.occupancyRate,
                backgroundColor: statusColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(room.occupancyRate * 100).toStringAsFixed(0)}% occupancy',
                style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 16, color: theme.colorScheme.primary),
      const SizedBox(width: 10),
      Text('$label: ', style: theme.textTheme.bodyMedium),
      Text(value,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

class _OccupantTile extends StatelessWidget {
  final AllocationModel alloc;
  const _OccupantTile({required this.alloc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final student = alloc.student;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            student?.name.isNotEmpty == true
                ? student!.name[0].toUpperCase()
                : '?',
            style: TextStyle(
                color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(student?.name ?? 'Unknown'),
        subtitle: Text(student?.usn ?? student?.email ?? ''),
        trailing: const Icon(Iconsax.user_tick, size: 18),
      ),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _roomDetailProvider =
    FutureProvider.family<RoomModel?, String>((ref, id) async {
  final result = await ref.watch(roomRepositoryProvider).getRoomById(id);
  return result.fold((_) => null, (r) => r);
});

final _occupantsProvider =
    FutureProvider.family<List<AllocationModel>, String>((ref, roomId) async {
  final result =
      await ref.watch(roomRepositoryProvider).getRoomOccupants(roomId);
  return result.fold((_) => [], (l) => l);
});
