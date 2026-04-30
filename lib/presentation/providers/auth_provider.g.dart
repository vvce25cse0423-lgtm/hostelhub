// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'auth_provider.dart';

String _$authNotifierHash() => r'an_hash';
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$AuthNotifier = AsyncNotifier<UserModel?>;

String _$themeModeNotifierHash() => r'tm_hash';
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, bool>.internal(
  ThemeModeNotifier.new,
  name: r'themeModeNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$themeModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$ThemeModeNotifier = Notifier<bool>;
