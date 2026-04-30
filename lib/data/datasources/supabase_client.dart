// lib/data/datasources/supabase_client.dart
// Supabase client initialization and auth state provider

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

part 'supabase_client.g.dart';

@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}

@riverpod
User? currentUser(Ref ref) {
  return Supabase.instance.client.auth.currentUser;
}

@riverpod
Session? currentSession(Ref ref) {
  return Supabase.instance.client.auth.currentSession;
}

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: false,
  );
}
