// lib/presentation/screens/attendance/attendance_screen.dart
// Attendance is ADMIN-CONTROLLED: admin marks present/absent for each student
// Students only VIEW their attendance record

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_snackbar.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) return const ShimmerLoader();

    if (user.isAdmin) {
      return _AdminAttendanceView();
    }
    return _StudentAttendanceView(studentId: user.id);
  }
}

// ─── STUDENT VIEW: Shows their own attendance + hostel status ─────────────────
class _StudentAttendanceView extends ConsumerWidget {
  final String studentId;
  const _StudentAttendanceView({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_attendanceHistoryProvider(studentId));
    final todayAsync = ref.watch(_todayAttendanceProvider(studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_attendanceHistoryProvider);
          ref.invalidate(_todayAttendanceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's hostel status card
              todayAsync.when(
                loading: () => const ShimmerLoader(height: 100),
                error: (_, __) => const SizedBox(),
                data: (record) => _TodayStatusCard(record: record),
              ),
              const SizedBox(height: 20),
              Text('Attendance History',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              historyAsync.when(
                loading: () => const ShimmerLoader(),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (records) => records.isEmpty
                    ? const EmptyState(
                        icon: Iconsax.clock,
                        title: 'No Records',
                        subtitle: 'Your attendance will appear here once admin marks it',
                      )
                    : Column(
                        children: records
                            .map((r) => _AttendanceRow(record: r))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final Map<String, dynamic>? record;
  const _TodayStatusCard({this.record});

  @override
  Widget build(BuildContext context) {
    final isPresent = record != null && record!['status'] == 'present';
    final hasRecord = record != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPresent
              ? [AppTheme.successGreen, const Color(0xFF059669)]
              : hasRecord
                  ? [AppTheme.errorRed, const Color(0xFFB91C1C)]
                  : [AppTheme.primaryBlue, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPresent ? Icons.home_rounded : Icons.not_interested_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  !hasRecord
                      ? 'Not marked yet today'
                      : isPresent
                          ? '✅ Present — You are in hostel'
                          : '❌ Absent — Not in hostel today',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (record != null) ...[
            const SizedBox(height: 8),
            Text('Marked by Warden/Admin',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = record['status'] == 'present';
    final date = DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isPresent ? AppTheme.successGreen : AppTheme.errorRed)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
          ),
        ),
        title: Text(DateFormat('EEEE, MMM d').format(date),
            style: theme.textTheme.titleSmall),
        subtitle: Text(isPresent ? 'Present' : 'Absent',
            style: TextStyle(
                color: isPresent ? AppTheme.successGreen : AppTheme.errorRed,
                fontWeight: FontWeight.w600)),
        trailing: Text(DateFormat('MMM d').format(date),
            style: theme.textTheme.labelSmall),
      ),
    );
  }
}

// ─── ADMIN VIEW: Mark attendance for all students ─────────────────────────────
class _AdminAttendanceView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdminAttendanceView> createState() =>
      _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends ConsumerState<_AdminAttendanceView> {
  DateTime _selectedDate = DateTime.now();
  bool _isMarking = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(_adminStudentsAttendanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.calendar_1),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date banner
          Container(
            width: double.infinity,
            color: AppTheme.primaryBlue.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(Iconsax.calendar, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                      color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedDate = DateTime.now()),
                  child: const Text('Today'),
                ),
              ],
            ),
          ),

          Expanded(
            child: studentsAsync.when(
              loading: () => const ShimmerLoader(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) => students.isEmpty
                  ? const EmptyState(
                      icon: Iconsax.people,
                      title: 'No Students',
                      subtitle: 'Add students to mark attendance',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: students.length,
                      itemBuilder: (ctx, i) => _AdminStudentAttendanceTile(
                        student: students[i],
                        date: _selectedDate,
                        onMarked: () => ref
                            .invalidate(_adminStudentsAttendanceProvider),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _AdminStudentAttendanceTile extends ConsumerStatefulWidget {
  final UserModel student;
  final DateTime date;
  final VoidCallback onMarked;
  const _AdminStudentAttendanceTile(
      {required this.student, required this.date, required this.onMarked});

  @override
  ConsumerState<_AdminStudentAttendanceTile> createState() =>
      _AdminStudentAttendanceTileState();
}

class _AdminStudentAttendanceTileState
    extends ConsumerState<_AdminStudentAttendanceTile> {
  bool _isLoading = false;
  String? _currentStatus;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final client = ref.read(supabaseClientProvider);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      final data = await client
          .from('attendance')
          .select('status')
          .eq('student_id', widget.student.id)
          .eq('date', dateStr)
          .maybeSingle();
      if (mounted) {
        setState(() => _currentStatus = data?['status'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _markAttendance(String status) async {
    setState(() => _isLoading = true);
    final client = ref.read(supabaseClientProvider);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      await client.from('attendance').upsert({
        'student_id': widget.student.id,
        'date': dateStr,
        'status': status,
        'marked_by': ref.read(currentUserProvider)?.id,
      }, onConflict: 'student_id,date');
      setState(() => _currentStatus = status);
      if (mounted) {
        AppSnackbar.showSuccess(
            context, '${widget.student.name} marked $status');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = _currentStatus == 'present';
    final isAbsent = _currentStatus == 'absent';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              radius: 20,
              child: Text(
                widget.student.name.isNotEmpty
                    ? widget.student.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.student.name,
                      style: theme.textTheme.titleSmall),
                  Text(widget.student.usn ?? widget.student.email,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusBtn(
                    label: 'P',
                    color: AppTheme.successGreen,
                    isSelected: isPresent,
                    onTap: () => _markAttendance('present'),
                  ),
                  const SizedBox(width: 8),
                  _StatusBtn(
                    label: 'A',
                    color: AppTheme.errorRed,
                    isSelected: isAbsent,
                    onTap: () => _markAttendance('absent'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  const _StatusBtn(
      {required this.label,
      required this.color,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _attendanceHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, studentId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .order('date', ascending: false)
        .limit(30);
    return (data as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
});

final _todayAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, studentId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await client
        .from('attendance')
        .select()
        .eq('student_id', studentId)
        .eq('date', today)
        .maybeSingle();
    return data as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
});

final _adminStudentsAttendanceProvider =
    FutureProvider<List<UserModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('users')
        .select()
        .eq('role', 'student')
        .order('name');
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  } catch (_) {
    return [];
  }
});
