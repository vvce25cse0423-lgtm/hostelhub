// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'supabase_client.dart';

String _$supabaseClientHash() => r'sc_hash';
@ProviderFor(supabaseClient)
final supabaseClientProvider = Provider<SupabaseClient>.internal(
  supabaseClient,
  name: r'supabaseClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$supabaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

String _$authStateHash() => r'as_hash';
@ProviderFor(authState)
final authStateProvider = StreamProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

String _$currentUserHash() => r'cu_hash';
@ProviderFor(currentUser)
final currentUserProvider = Provider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

String _$currentSessionHash() => r'cs_hash';
@ProviderFor(currentSession)
final currentSessionProvider = Provider<Session?>.internal(
  currentSession,
  name: r'currentSessionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
