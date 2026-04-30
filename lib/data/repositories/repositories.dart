// lib/data/repositories/repositories.dart
// All non-auth repositories: Room, Attendance, Fee, Notification

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../datasources/supabase_client.dart';
import '../models/models.dart';

part 'repositories.g.dart';

// ─── Room Repository ───────────────────────────────────────────────────────────
@riverpod
RoomRepository roomRepository(Ref ref) {
  return RoomRepository(ref.watch(supabaseClientProvider));
}

class RoomRepository {
  final SupabaseClient _client;
  RoomRepository(this._client);

  // FIX: Apply all filters on PostgrestFilterBuilder BEFORE .order()/.limit()
  Future<Either<Failure, List<RoomModel>>> getRooms({
    String? status,
    String? type,
    String? floor,
  }) async {
    try {
      // Start with filter builder
      var query = _client.from(AppConstants.roomsTable).select();

      // Apply filters while still a filter builder
      if (status != null) query = query.eq('status', status);
      if (type != null) query = query.eq('type', type);
      if (floor != null) query = query.eq('floor', floor);

      // Apply ordering last (converts to transform builder)
      final data = await query.order('room_number');
      return Right((data as List).map((e) => RoomModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load rooms: $e'));
    }
  }

  Future<Either<Failure, RoomModel>> getRoomById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.roomsTable)
          .select()
          .eq('id', id)
          .single();
      return Right(RoomModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load room: $e'));
    }
  }

  Future<Either<Failure, AllocationModel?>> getStudentAllocation(
      String studentId) async {
    try {
      final data = await _client
          .from(AppConstants.allocationsTable)
          .select('*, rooms(*)')
          .eq('student_id', studentId)
          .eq('is_active', true)
          .maybeSingle();
      if (data == null) return const Right(null);
      return Right(AllocationModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load allocation: $e'));
    }
  }

  Future<Either<Failure, List<AllocationModel>>> getRoomOccupants(
      String roomId) async {
    try {
      final data = await _client
          .from(AppConstants.allocationsTable)
          .select('*, users(*)')
          .eq('room_id', roomId)
          .eq('is_active', true);
      return Right(
          (data as List).map((e) => AllocationModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load occupants: $e'));
    }
  }

  Future<Either<Failure, AllocationModel>> assignRoom({
    required String studentId,
    required String roomId,
  }) async {
    try {
      final roomData = await _client
          .from(AppConstants.roomsTable)
          .select()
          .eq('id', roomId)
          .single();
      final room = RoomModel.fromJson(roomData);
      if (!room.isAvailable) {
        return Left(const ValidationFailure(message: 'Room is not available'));
      }
      await _client
          .from(AppConstants.allocationsTable)
          .update({
            'is_active': false,
            'vacated_at': DateTime.now().toIso8601String(),
          })
          .eq('student_id', studentId)
          .eq('is_active', true);
      final allocationData = await _client
          .from(AppConstants.allocationsTable)
          .insert({
            'student_id': studentId,
            'room_id': roomId,
            'allocated_at': DateTime.now().toIso8601String(),
            'is_active': true,
          })
          .select('*, rooms(*), users(*)')
          .single();
      return Right(AllocationModel.fromJson(allocationData));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to assign room: $e'));
    }
  }

  Future<Either<Failure, RoomModel>> updateRoom({
    required String roomId,
    String? status,
    double? monthlyRent,
    String? amenities,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (monthlyRent != null) updates['monthly_rent'] = monthlyRent;
      if (amenities != null) updates['amenities'] = amenities;
      final data = await _client
          .from(AppConstants.roomsTable)
          .update(updates)
          .eq('id', roomId)
          .select()
          .single();
      return Right(RoomModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update room: $e'));
    }
  }

  Future<Either<Failure, Map<String, int>>> getRoomStats() async {
    try {
      final data =
          await _client.from(AppConstants.roomsTable).select('status');
      final rooms = data as List;
      return Right({
        'total': rooms.length,
        'available': rooms.where((r) => r['status'] == 'available').length,
        'full': rooms.where((r) => r['status'] == 'full').length,
        'maintenance':
            rooms.where((r) => r['status'] == 'maintenance').length,
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load room stats: $e'));
    }
  }
}

// ─── Attendance Repository ────────────────────────────────────────────────────
@riverpod
AttendanceRepository attendanceRepository(Ref ref) {
  return AttendanceRepository(ref.watch(supabaseClientProvider));
}

class AttendanceRepository {
  final SupabaseClient _client;
  AttendanceRepository(this._client);

  // FIX: filters before .order()/.limit()
  Future<Either<Failure, List<AttendanceModel>>> getAttendanceHistory({
    required String studentId,
    DateTime? from,
    DateTime? to,
    int limit = 30,
  }) async {
    try {
      // Build filters first
      var query = _client
          .from(AppConstants.attendanceTable)
          .select()
          .eq('student_id', studentId);

      if (from != null) query = query.gte('check_in', from.toIso8601String());
      if (to != null) query = query.lte('check_in', to.toIso8601String());

      // Order and limit last
      final data = await query.order('check_in', ascending: false).limit(limit);
      return Right(
          (data as List).map((e) => AttendanceModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load attendance: $e'));
    }
  }

  Future<Either<Failure, AttendanceModel?>> getTodayAttendance(
      String studentId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final data = await _client
          .from(AppConstants.attendanceTable)
          .select()
          .eq('student_id', studentId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .order('check_in', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return const Right(null);
      return Right(AttendanceModel.fromJson(data));
    } catch (e) {
      return Left(
          ServerFailure(message: "Failed to load today's attendance: $e"));
    }
  }

  Future<Either<Failure, AttendanceModel>> checkIn({
    required String studentId,
    String? notes,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.attendanceTable)
          .insert({
            'student_id': studentId,
            'check_in': DateTime.now().toIso8601String(),
            if (notes != null) 'notes': notes,
          })
          .select()
          .single();
      return Right(AttendanceModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark check-in: $e'));
    }
  }

  Future<Either<Failure, AttendanceModel>> checkOut({
    required String attendanceId,
    String? notes,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.attendanceTable)
          .update({
            'check_out': DateTime.now().toIso8601String(),
            if (notes != null) 'notes': notes,
          })
          .eq('id', attendanceId)
          .select()
          .single();
      return Right(AttendanceModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark check-out: $e'));
    }
  }
}

// ─── Fee Repository ───────────────────────────────────────────────────────────
@riverpod
FeeRepository feeRepository(Ref ref) {
  return FeeRepository(ref.watch(supabaseClientProvider));
}

class FeeRepository {
  final SupabaseClient _client;
  FeeRepository(this._client);

  // FIX: filter before .order()
  Future<Either<Failure, List<FeeModel>>> getStudentFees({
    required String studentId,
    String? status,
  }) async {
    try {
      var query = _client
          .from(AppConstants.feesTable)
          .select()
          .eq('student_id', studentId);

      if (status != null) query = query.eq('status', status);

      final data = await query.order('due_date', ascending: false);
      return Right((data as List).map((e) => FeeModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load fees: $e'));
    }
  }

  // FIX: filter before .order()
  Future<Either<Failure, List<FeeModel>>> getAllFees({String? status}) async {
    try {
      var query = _client
          .from(AppConstants.feesTable)
          .select('*, users!fees_student_id_fkey(id, name, email, usn)');

      if (status != null) query = query.eq('status', status);

      final data = await query.order('due_date', ascending: false);
      return Right((data as List).map((e) => FeeModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load all fees: $e'));
    }
  }

  Future<Either<Failure, FeeModel>> markAsPaid({
    required String feeId,
    required String transactionId,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.feesTable)
          .update({
            'status': AppConstants.feePaid,
            'paid_at': DateTime.now().toIso8601String(),
            'transaction_id': transactionId,
          })
          .eq('id', feeId)
          .select()
          .single();
      return Right(FeeModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update payment: $e'));
    }
  }

  Future<Either<Failure, Map<String, double>>> getFeeSummary(
      String studentId) async {
    try {
      final data = await _client
          .from(AppConstants.feesTable)
          .select('amount, status')
          .eq('student_id', studentId);
      final fees = data as List;
      double paid = 0, pending = 0, overdue = 0;
      for (final fee in fees) {
        final amount = (fee['amount'] as num).toDouble();
        switch (fee['status'] as String) {
          case 'paid':
            paid += amount;
          case 'pending':
            pending += amount;
          case 'overdue':
            overdue += amount;
        }
      }
      return Right({
        'paid': paid,
        'pending': pending,
        'overdue': overdue,
        'total': paid + pending + overdue,
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load fee summary: $e'));
    }
  }
}

// ─── Notification Repository ──────────────────────────────────────────────────
@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
}

class NotificationRepository {
  final SupabaseClient _client;
  NotificationRepository(this._client);

  // FIX: filter before .order()/.limit()
  Future<Either<Failure, List<NotificationModel>>> getNotifications({
    required String userId,
    bool unreadOnly = false,
  }) async {
    try {
      var query = _client
          .from(AppConstants.notificationsTable)
          .select()
          .eq('user_id', userId);

      if (unreadOnly) query = query.eq('is_read', false);

      final data = await query.order('created_at', ascending: false).limit(50);
      return Right(
          (data as List).map((e) => NotificationModel.fromJson(e)).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load notifications: $e'));
    }
  }

  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true}).eq('id', notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark as read: $e'));
    }
  }

  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to mark all as read: $e'));
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      return (data as List).length;
    } catch (_) {
      return 0;
    }
  }

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _client
        .from(AppConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((e) => e['user_id'] == userId)
            .map((e) => NotificationModel.fromJson(e))
            .toList());
  }
}
