// lib/presentation/providers/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/supabase_client.dart';

part 'auth_provider.g.dart';

// ─── Auth Notifier ─────────────────────────────────────────────────────────────
// FIX: AsyncNotifier.build() must return FutureOr<T>, not AsyncValue<T>
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<UserModel?> build() async {
    final session = ref.read(currentSessionProvider);
    if (session == null) return null;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getCurrentUser();
    return result.fold((_) => null, (user) => user);
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email: email, password: password);

    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String usn,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(
      email: email,
      password: password,
      name: name,
      usn: usn,
    );

    return result.fold(
      (failure) {
        state = const AsyncValue.data(null);
        return failure.message;
      },
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
  }

  Future<String?> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.updateProfile(
      userId: userId,
      name: name,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );

    return result.fold(
      (failure) => failure.message,
      (user) {
        state = AsyncValue.data(user);
        return null;
      },
    );
  }
}

// ─── Theme Mode ────────────────────────────────────────────────────────────────
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  bool build() => false;
  void toggle() => state = !state;
}
