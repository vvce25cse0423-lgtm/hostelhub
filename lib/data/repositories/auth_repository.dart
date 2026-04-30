// lib/data/repositories/auth_repository.dart
// Authentication repository using Supabase Auth

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// FIX: Import supabase with a prefix to avoid AuthException name clash
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../datasources/supabase_client.dart';
import '../models/models.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

class AuthRepository {
  final sb.SupabaseClient _client;
  AuthRepository(this._client);

  Future<Either<AuthFailure, UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        return Left(const AuthFailure(message: 'Login failed. Please try again.'));
      }
      return _getUserProfile(response.user!.id);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.message), code: e.statusCode));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<Either<AuthFailure, UserModel>> signUp({
    required String email,
    required String password,
    required String name,
    required String usn,
    String role = AppConstants.roleStudent,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name, 'role': role, 'usn': usn},
      );
      if (response.user == null) {
        return Left(const AuthFailure(message: 'Registration failed. Please try again.'));
      }
      await _client.from(AppConstants.usersTable).upsert({
        'id': response.user!.id,
        'name': name,
        'email': email.trim(),
        'role': role,
        'usn': usn,
        'created_at': DateTime.now().toIso8601String(),
      });
      return _getUserProfile(response.user!.id);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.message), code: e.statusCode));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Right(null);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    }
  }

  Future<Either<AuthFailure, UserModel>> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Left(const AuthFailure(message: 'No authenticated user'));
    }
    return _getUserProfile(user.id);
  }

  Future<Either<ServerFailure, UserModel>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      final data = await _client
          .from(AppConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return Right(UserModel.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<AuthFailure, void>> changePassword({
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
      return const Right(null);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    }
  }

  Future<Either<AuthFailure, UserModel>> _getUserProfile(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();
      return Right(UserModel.fromJson(data));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to load user profile: $e'));
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (message.contains('Email not confirmed')) {
      return 'Please verify your email before logging in.';
    } else if (message.contains('User already registered')) {
      return 'An account with this email already exists.';
    } else if (message.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return message;
  }
}
