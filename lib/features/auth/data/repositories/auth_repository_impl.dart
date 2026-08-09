import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] using the Supabase Auth Client.
class AuthRepositoryImpl implements AuthRepository {
  final supabase.SupabaseClient _supabaseClient;

  AuthRepositoryImpl(this._supabaseClient);


  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const FormatException('Signup was successful, but no user data was returned.');
      }
      return AppUser(id: user.id, email: user.email ?? '');
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during signup: $e');
    }
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const FormatException('Signin was successful, but no user data was returned.');
      }
      return AppUser(id: user.id, email: user.email ?? '');
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during signin: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred during signout: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }



  @override
  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        type: supabase.OtpType.recovery,
        email: email,
        token: token,
      );
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    try {
      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      // 1. Initiate Supabase OAuth flow with Google
      final bool launched = await _supabaseClient.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );


      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        return AppUser(id: user.id, email: user.email ?? '');
      }

      if (!launched) {
        throw Exception('Google authentication failed to launch.');
      }
      
      // Return transient user state if redirected
      return AppUser(
        id: user?.id ?? 'pending',
        email: user?.email ?? 'google_user',
      );
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Google sign-in error: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No active authenticated session found.');
      }
      // Re-authenticate user to verify current password
      await _supabaseClient.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
      // Update to new password
      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
    } on supabase.AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }


  @override
  AppUser? get currentUser {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _supabaseClient.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user == null) return null;
      return AppUser(id: user.id, email: user.email ?? '');
    });
  }
}
