// lib/presentation/screens/fees/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_snackbar.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) return const ShimmerLoader();

    return user.isAdmin ? _AdminFeesView() : _StudentFeesView(userId: user.id);
  }
}

// ─── STUDENT VIEW ─────────────────────────────────────────────────────────────
class _StudentFeesView extends ConsumerWidget {
  final String userId;
  const _StudentFeesView({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(_studentFeesProvider(userId));
    final summaryAsync = ref.watch(_feeSummaryProvider(userId));
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Fees & Payments')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_studentFeesProvider);
          ref.invalidate(_feeSummaryProvider);
        },
        child: summaryAsync.when(
          loading: () => const ShimmerLoader(),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading fees: $e'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_feeSummaryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (summary) => feesAsync.when(
            loading: () => const ShimmerLoader(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (fees) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                if (summary != null) _SummaryCard(summary: summary, fmt: fmt),
                const SizedBox(height: 20),
                Text('Payment History',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (fees.isEmpty)
                  const EmptyState(
                    icon: Iconsax.wallet,
                    title: 'No Fee Records',
                    subtitle: 'Your fee records will appear here',
                  )
                else
                  ...fees.map((fee) => _FeeCard(
                      fee: fee,
                      fmt: fmt,
                      onPaid: () {
                        ref.invalidate(_studentFeesProvider);
                        ref.invalidate(_feeSummaryProvider);
                      })),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> summary;
  final NumberFormat fmt;
  const _SummaryCard({required this.summary, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final totalDue = (summary['pending'] ?? 0) + (summary['overdue'] ?? 0);
    final hasOverdue = (summary['overdue'] ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasOverdue
              ? [AppTheme.errorRed, const Color(0xFFB91C1C)]
              : totalDue > 0
                  ? [AppTheme.warningOrange, const Color(0xFFD97706)]
                  : [AppTheme.successGreen, const Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Due',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(fmt.format(totalDue),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryPill(label: 'Paid', value: fmt.format(summary['paid'] ?? 0)),
              const SizedBox(width: 12),
              _SummaryPill(
                  label: 'Pending', value: fmt.format(summary['pending'] ?? 0)),
              if (hasOverdue) ...[
                const SizedBox(width: 12),
                _SummaryPill(
                    label: 'Overdue', value: fmt.format(summary['overdue'] ?? 0)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label, value;
  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value',
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _FeeCard extends ConsumerWidget {
  final FeeModel fee;
  final NumberFormat fmt;
  final VoidCallback onPaid;
  const _FeeCard(
      {required this.fee, required this.fmt, required this.onPaid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOverdue = fee.isOverdue;

    Color statusColor = fee.isPaid
        ? AppTheme.successGreen
        : isOverdue
            ? AppTheme.errorRed
            : AppTheme.warningOrange;
    String statusLabel =
        fee.isPaid ? 'Paid' : isOverdue ? 'Overdue' : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.wallet, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee.feeType
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w.isNotEmpty
                                ? w[0].toUpperCase() + w.substring(1)
                                : '')
                            .join(' '),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(fee.month, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmt.format(fee.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
            if (!fee.isPaid) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Iconsax.calendar_2,
                      size: 13,
                      color:
                          isOverdue ? AppTheme.errorRed : theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(fee.dueDate)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? AppTheme.errorRed
                            : theme.colorScheme.outline,
                        fontWeight:
                            isOverdue ? FontWeight.w600 : FontWeight.normal),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _pay(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      backgroundColor:
                          isOverdue ? AppTheme.errorRed : null,
                    ),
                    child:
                        const Text('Pay Now', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
            if (fee.isPaid && fee.paidAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 13, color: AppTheme.successGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Paid on ${DateFormat('dd MMM yyyy').format(fee.paidAt!)}',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.successGreen),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
            'Pay ${NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 0).format(fee.amount)} for ${fee.feeType.replaceAll("_", " ")}?\n\n(Mock payment for demo)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Pay')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = ref.read(feeRepositoryProvider);
    final txnId = 'TXN${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final result = await repo.markAsPaid(feeId: fee.id, transactionId: txnId);

    if (context.mounted) {
      result.fold(
        (f) => AppSnackbar.showError(context, f.message),
        (_) {
          AppSnackbar.showSuccess(context, 'Payment successful! Txn: $txnId');
          onPaid();
        },
      );
    }
  }
}

// ─── ADMIN FEES VIEW ──────────────────────────────────────────────────────────
class _AdminFeesView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(_allFeesProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFeeDialog(context, ref),
          ),
        ],
      ),
      body: feesAsync.when(
        loading: () => const ShimmerLoader(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              ElevatedButton(
                  onPressed: () => ref.invalidate(_allFeesProvider),
                  child: const Text('Retry')),
            ],
          ),
        ),
        data: (fees) => fees.isEmpty
            ? const EmptyState(
                icon: Iconsax.wallet,
                title: 'No Fees',
                subtitle: 'Add fees using the + button',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_allFeesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: fees.length,
                  itemBuilder: (ctx, i) {
                    final fee = fees[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                            '${fee.student?.name ?? "Unknown"} — ${fee.feeType.replaceAll("_", " ")}'),
                        subtitle: Text(
                            '${fee.month} • ${fee.student?.usn ?? ""}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmt.format(fee.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(fee.status,
                                style: TextStyle(
                                    color: fee.isPaid
                                        ? AppTheme.successGreen
                                        : AppTheme.warningOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _showAddFeeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddFeeDialog(
          onAdded: () => ref.invalidate(_allFeesProvider)),
    );
  }
}

class _AddFeeDialog extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddFeeDialog({required this.onAdded});

  @override
  ConsumerState<_AddFeeDialog> createState() => _AddFeeDialogState();
}

class _AddFeeDialogState extends ConsumerState<_AddFeeDialog> {
  final _amountCtrl = TextEditingController();
  String _feeType = 'hostel';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Fee for All Students'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _feeType,
            items: ['hostel', 'mess', 'other']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _feeType = v ?? 'hostel'),
            decoration: const InputDecoration(labelText: 'Fee Type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Amount', prefixText: '₹'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : () => _addFee(context),
          child:
              _loading ? const CircularProgressIndicator() : const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _addFee(BuildContext context) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      AppSnackbar.showError(context, 'Enter valid amount');
      return;
    }
    setState(() => _loading = true);
    final client = ref.read(supabaseClientProvider);
    try {
      final students = await client
          .from('users')
          .select('id')
          .eq('role', 'student');
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      final dueDate =
          DateTime.now().add(const Duration(days: 15)).toIso8601String();
      final records = (students as List)
          .map((s) => {
                'student_id': s['id'],
                'amount': amount,
                'fee_type': _feeType,
                'month': month,
                'due_date': dueDate,
                'status': 'pending',
              })
          .toList();
      await client.from('fees').insert(records);
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, 'Fees added for all students!');
        widget.onAdded();
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final _studentFeesProvider =
    FutureProvider.family<List<FeeModel>, String>((ref, userId) async {
  try {
    final repo = ref.watch(feeRepositoryProvider);
    final result = await repo.getStudentFees(studentId: userId);
    return result.fold((_) => [], (l) => l);
  } catch (_) {
    return [];
  }
});

final _feeSummaryProvider =
    FutureProvider.family<Map<String, double>?, String>((ref, userId) async {
  try {
    final repo = ref.watch(feeRepositoryProvider);
    final result = await repo.getFeeSummary(userId);
    return result.fold((_) => null, (s) => s);
  } catch (_) {
    return null;
  }
});

final _allFeesProvider = FutureProvider<List<FeeModel>>((ref) async {
  try {
    final repo = ref.watch(feeRepositoryProvider);
    final result = await repo.getAllFees();
    return result.fold((_) => [], (l) => l);
  } catch (_) {
    return [];
  }
});
