import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/core/network/supabase_client.dart';
import 'package:mazad/features/auth/data/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Streams Supabase auth state. Emits the current [Session] (or null when
/// signed out). The router watches this to redirect signed-out users.
final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (!MazadSupabase.isConfigured) {
    // Phase 0 boot path: no backend wired. Emit null so the router treats
    // the user as signed-out.
    return Stream<AuthState?>.value(null);
  }
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Convenience: the current [User] or null. Synchronous read off
/// `currentSession` so widgets that need it on first build don't have to
/// wait for the stream.
final currentUserProvider = Provider<User?>((ref) {
  // Re-read whenever auth state changes.
  ref.watch(authStateProvider);
  if (!MazadSupabase.isConfigured) return null;
  return Supabase.instance.client.auth.currentUser;
});

/// Loads the caller's [MazadProfile] row from the `profiles` table.
/// Returns null when signed-out. The bootstrap trigger guarantees a row
/// exists for every signed-in user.
final myProfileProvider = FutureProvider<MazadProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final res = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (res == null) return null;
  return MazadProfile.fromJson(res);
});
