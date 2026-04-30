// lib/core/errors/failures.dart
// Domain-layer failure types - renamed AppAuthException to avoid clash with Supabase

import 'package:equatable/equatable.dart';

/// Base class for all application failures
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  const Failure({required this.message, this.code});
  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

// RENAMED from AuthFailure to AppAuthFailure to avoid clash with Supabase's AuthException
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Failed to load cached data.',
    super.code,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permission denied.',
    super.code,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.code,
  });
}
