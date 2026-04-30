// lib/data/repositories/complaint_repository.dart
// Complaint management with Supabase Storage for images

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../datasources/supabase_client.dart';
import '../models/models.dart';

part 'complaint_repository.g.dart';

@riverpod
ComplaintRepository complaintRepository(Ref ref) {
  return ComplaintRepository(ref.watch(supabaseClientProvider));
}

class ComplaintRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ComplaintRepository(this._client);

  // FIX: Apply filters on filter builder BEFORE .order()/.range()
  Future<Either<Failure, List<ComplaintModel>>> getComplaints({
    String? studentId,
    String? status,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    try {
      // Start query with select (returns filter builder)
      var query = _client
          .from(AppConstants.complaintsTable)
          .select('*, users!complaints_student_id_fkey(id, name, email, usn)');

      // Apply all filters while still on filter builder
      if (studentId != null) query = query.eq('student_id', studentId);
      if (status != null) query = query.eq('status', status);

      // Apply ordering and pagination last (converts to transform builder)
      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final complaints =
          (data as List).map((e) => ComplaintModel.fromJson(e)).toList();
      return Right(complaints);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load complaints: $e'));
    }
  }

  Future<Either<Failure, ComplaintModel>> getComplaintById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.complaintsTable)
          .select('*, users!complaints_student_id_fkey(id, name, email, usn)')
          .eq('id', id)
          .single();
      return Right(ComplaintModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to load complaint: $e'));
    }
  }

  Future<Either<Failure, ComplaintModel>> createComplaint({
    required String studentId,
    required String title,
    required String description,
    required String category,
    File? image,
  }) async {
    try {
      String? imageUrl;
      if (image != null) {
        final uploadResult = await _uploadComplaintImage(image, studentId);
        imageUrl = uploadResult.fold((_) => null, (url) => url);
      }

      final complaintData = {
        'id': _uuid.v4(),
        'student_id': studentId,
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'status': AppConstants.complaintPending,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final data = await _client
          .from(AppConstants.complaintsTable)
          .insert(complaintData)
          .select('*, users!complaints_student_id_fkey(id, name, email, usn)')
          .single();

      return Right(ComplaintModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to create complaint: $e'));
    }
  }

  Future<Either<Failure, ComplaintModel>> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? adminNote,
    String? resolvedBy,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        if (adminNote != null) 'admin_note': adminNote,
        if (resolvedBy != null) 'resolved_by': resolvedBy,
        if (status == AppConstants.complaintResolved)
          'resolved_at': DateTime.now().toIso8601String(),
      };

      final data = await _client
          .from(AppConstants.complaintsTable)
          .update(updates)
          .eq('id', complaintId)
          .select('*, users!complaints_student_id_fkey(id, name, email, usn)')
          .single();

      return Right(ComplaintModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update complaint: $e'));
    }
  }

  Future<Either<Failure, String>> _uploadComplaintImage(
      File image, String studentId) async {
    try {
      final fileName = '${studentId}_${_uuid.v4()}.jpg';
      final path = 'complaints/$fileName';

      await _client.storage
          .from(AppConstants.complaintImagesBucket)
          .upload(path, image,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ));

      final publicUrl = _client.storage
          .from(AppConstants.complaintImagesBucket)
          .getPublicUrl(path);

      return Right(publicUrl);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to upload image: $e'));
    }
  }

  // FIX: SupabaseStreamBuilder does not support .eq() chaining
  // Use .stream() with eq param directly, then filter in map
  Stream<List<ComplaintModel>> complaintsStream(String? studentId) {
    final stream = _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return stream.map((data) {
      var list = data.map((e) => ComplaintModel.fromJson(e)).toList();
      if (studentId != null) {
        list = list.where((c) => c.studentId == studentId).toList();
      }
      return list;
    });
  }
}
