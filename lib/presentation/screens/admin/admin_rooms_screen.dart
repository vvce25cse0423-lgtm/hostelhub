// lib/presentation/screens/admin/admin_rooms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_snackbar.dart';

// ─── Admin Rooms Screen ───────────────────────────────────────────────────────
class AdminRoomsScreen extends ConsumerWidget {
  const AdminRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(_adminRoomsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Room Management')),
      body: roomsAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rooms) => rooms.isEmpty
            ? const EmptyState(
                icon: Iconsax.building,
                title: 'No Rooms',
                subtitle: 'Add rooms in Supabase to get started')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_adminRoomsListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (ctx, i) => _AdminRoomTile(room: rooms[i])
                      .animate()
                      .fadeIn(delay: (i * 50).ms),
                ),
              ),
      ),
    );
  }
}

class _AdminRoomTile extends ConsumerWidget {
  final RoomModel room;
  const _AdminRoomTile({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final Color statusColor = room.status == 'available'
        ? AppTheme.successGreen
        : room.status == 'full'
            ? AppTheme.errorRed
            : AppTheme.warningOrange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Room ${room.roomNumber}',
                  style: theme.textTheme.titleMedium),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) => _handleStatus(context, ref, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'available', child: Text('Mark Available')),
                  PopupMenuItem(value: 'maintenance', child: Text('Mark Maintenance')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(room.status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    Icon(Icons.arrow_drop_down, color: statusColor, size: 16),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              _Chip(icon: Iconsax.building, label: 'Floor ${room.floor}'),
              _Chip(icon: Iconsax.people, label: '${room.occupancy}/${room.capacity}'),
              _Chip(icon: Icons.king_bed_outlined, label: room.type),
              if (room.monthlyRent != null)
                _Chip(icon: Iconsax.money, label: '₹${room.monthlyRent!.toStringAsFixed(0)}'),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: room.occupancyRate,
                backgroundColor: statusColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatus(
      BuildContext context, WidgetRef ref, String status) async {
    final result = await ref
        .read(roomRepositoryProvider)
        .updateRoom(roomId: room.id, status: status);
    if (context.mounted) {
      result.fold(
        (f) => AppSnackbar.showError(context, f.message),
        (_) {
          AppSnackbar.showSuccess(context, 'Room ${room.roomNumber} updated!');
          ref.invalidate(_adminRoomsListProvider);
        },
      );
    }
  }
}

// ─── Admin Students Screen ────────────────────────────────────────────────────
class AdminStudentsScreen extends ConsumerWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_adminStudentsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Student Management')),
      body: studentsAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (students) => students.isEmpty
            ? const EmptyState(
                icon: Iconsax.people,
                title: 'No Students',
                subtitle: 'No students have registered yet')
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(_adminStudentsListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) => _StudentTile(student: students[i])
                      .animate()
                      .fadeIn(delay: (i * 40).ms),
                ),
              ),
      ),
    );
  }
}

class _StudentTile extends ConsumerWidget {
  final UserModel student;
  const _StudentTile({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allocAsync = ref.watch(_studentAllocProvider(student.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          radius: 24,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
        ),
        title: Text(student.name, style: theme.textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.usn ?? student.email, style: theme.textTheme.bodySmall),
            allocAsync.when(
              loading: () => const SizedBox(height: 4),
              error: (_, __) => const SizedBox(),
              data: (alloc) => alloc != null
                  ? Row(children: [
                      Icon(Iconsax.building, size: 11, color: AppTheme.successGreen),
                      const SizedBox(width: 4),
                      Text('Room ${alloc.room?.roomNumber ?? "?"}',
                          style: TextStyle(
                              color: AppTheme.successGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ])
                  : Row(children: [
                      Icon(Iconsax.warning_2, size: 11,
                          color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text('No room assigned',
                          style: TextStyle(
                              color: theme.colorScheme.outline, fontSize: 11)),
                    ]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {
            if (v == 'assign') _showAssign(context, ref, student.id);
          },
          itemBuilder: (_) => const [
            // FIX: replaced Iconsax.building_add with Iconsax.building_3
            PopupMenuItem(
              value: 'assign',
              child: Row(children: [
                Icon(Iconsax.building_3, size: 16),
                SizedBox(width: 8),
                Text('Assign Room'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssign(
      BuildContext context, WidgetRef ref, String studentId) async {
    final repo = ref.read(roomRepositoryProvider);
    final result = await repo.getRooms(status: 'available');
    final rooms = result.fold((_) => <RoomModel>[], (l) => l);

    if (!context.mounted) return;
    if (rooms.isEmpty) {
      AppSnackbar.showError(context, 'No available rooms');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Room'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rooms.length,
            itemBuilder: (_, i) {
              final r = rooms[i];
              return ListTile(
                title: Text('Room ${r.roomNumber}'),
                subtitle: Text(
                    '${r.availableSlots} slots free • Floor ${r.floor}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await ref
                      .read(roomRepositoryProvider)
                      .assignRoom(studentId: studentId, roomId: r.id);
                  if (context.mounted) {
                    res.fold(
                      (f) => AppSnackbar.showError(context, f.message),
                      (_) {
                        AppSnackbar.showSuccess(
                            context, 'Room ${r.roomNumber} assigned!');
                        ref.invalidate(_studentAllocProvider);
                        ref.invalidate(_adminRoomsListProvider);
                      },
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ]),
      );
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _adminRoomsListProvider = FutureProvider<List<RoomModel>>((ref) async {
  final result = await ref.watch(roomRepositoryProvider).getRooms();
  return result.fold((_) => [], (l) => l);
});

final _adminStudentsListProvider =
    FutureProvider<List<UserModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('role', 'student')
        .order('name');
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  } catch (_) {
    return [];
  }
});

final _studentAllocProvider =
    FutureProvider.family<AllocationModel?, String>((ref, studentId) async {
  final result =
      await ref.watch(roomRepositoryProvider).getStudentAllocation(studentId);
  return result.fold((_) => null, (a) => a);
});
