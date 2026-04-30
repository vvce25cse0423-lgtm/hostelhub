// lib/presentation/screens/rooms/room_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String? _filterStatus;
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(_roomsProvider((
      status: _filterStatus,
      type: _filterType,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filter Chips ───────────────────────────────────────────────
          if (_filterStatus != null || _filterType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_filterStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_filterStatus!),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _filterStatus = null),
                      ),
                    ),
                  if (_filterType != null)
                    FilterChip(
                      label: Text(_filterType!),
                      selected: true,
                      onSelected: (_) => setState(() => _filterType = null),
                    ),
                ],
              ),
            ),

          // ─── Room Grid ──────────────────────────────────────────────────
          Expanded(
            child: roomsAsync.when(
              loading: () => const ShimmerLoader(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const EmptyState(
                    icon: Iconsax.building,
                    title: 'No Rooms Found',
                    subtitle: 'Try adjusting your filters',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_roomsProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, i) => _RoomCard(room: rooms[i])
                        .animate()
                        .fadeIn(delay: (i * 40).ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Rooms',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Status', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['available', 'full', 'maintenance'].map((s) {
                return FilterChip(
                  label: Text(s),
                  selected: _filterStatus == s,
                  onSelected: (v) {
                    setState(() => _filterStatus = v ? s : null);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('Type', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['single', 'double', 'triple'].map((t) {
                return FilterChip(
                  label: Text(t),
                  selected: _filterType == t,
                  onSelected: (v) {
                    setState(() => _filterType = v ? t : null);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;
    switch (room.status) {
      case 'available':
        statusColor = AppTheme.successGreen;
        statusIcon = Iconsax.tick_circle;
      case 'full':
        statusColor = AppTheme.errorRed;
        statusIcon = Iconsax.close_circle;
      default:
        statusColor = AppTheme.warningOrange;
        statusIcon = Iconsax.warning_2;
    }

    return Card(
      child: InkWell(
        onTap: () => context.go('/student/rooms/${room.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Iconsax.building,
                        color: theme.colorScheme.primary, size: 22),
                  ),
                  Icon(statusIcon, color: statusColor, size: 18),
                ],
              ),
              const Spacer(),
              Text('Room ${room.roomNumber}',
                  style: theme.textTheme.titleMedium),
              Text('Floor ${room.floor}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              // Occupancy bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: room.occupancyRate,
                  backgroundColor: statusColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${room.occupancy}/${room.capacity} beds',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              if (room.monthlyRent != null)
                Text(
                  '₹${room.monthlyRent!.toStringAsFixed(0)}/mo',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
typedef _RoomsArgs = ({String? status, String? type});

final _roomsProvider =
    FutureProvider.family<List<RoomModel>, _RoomsArgs>((ref, args) async {
  final repo = ref.watch(roomRepositoryProvider);
  final result =
      await repo.getRooms(status: args.status, type: args.type);
  return result.fold((_) => [], (list) => list);
});
