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
      return AppUser(
        id: user.id, 
        email: user.email ?? '',
        authProvider: user.appMetadata['provider'] as String?,
      );
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
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      final user = response.user;
      if (user == null) {
        throw const FormatException('Signin was successful, but no user data was returned.');
      }
      return AppUser(
        id: user.id, 
        email: user.email ?? cleanEmail,
        authProvider: user.appMetadata['provider'] as String?,
      );
    } on supabase.AuthException catch (e) {
      // Check fallback: If admin added/edited user in Web Settings with this password, sync & login!
      try {
        final teamUserRes = await _supabaseClient
            .from('team_users')
            .select('*')
            .ilike('email', cleanEmail)
            .maybeSingle();

        if (teamUserRes != null) {
          final isActive = teamUserRes['is_active'] != false;
          if (!isActive) {
            throw Exception('This account is deactivated. Please contact your administrator.');
          }

          final dbPassword = teamUserRes['password']?.toString() ?? '';
          if (dbPassword.isNotEmpty && dbPassword == cleanPassword) {
            // Password matches credentials set in web portal!
            // 1. Sync password in auth via RPC
            try {
              await _supabaseClient.rpc('admin_set_user_password', params: {
                'target_email': cleanEmail,
                'new_password': cleanPassword,
              });
              final retryRes = await _supabaseClient.auth.signInWithPassword(
                email: cleanEmail,
                password: cleanPassword,
              );
              if (retryRes.user != null) {
                return AppUser(
                  id: retryRes.user!.id,
                  email: retryRes.user!.email ?? cleanEmail,
                  authProvider: retryRes.user!.appMetadata['provider'] as String?,
                );
              }
            } catch (_) {}

            // 2. If user wasn't registered in auth at all, sign up directly
            try {
              final signUpRes = await _supabaseClient.auth.signUp(
                email: cleanEmail,
                password: cleanPassword,
              );
              if (signUpRes.user != null) {
                return AppUser(
                  id: signUpRes.user!.id,
                  email: signUpRes.user!.email ?? cleanEmail,
                  authProvider: signUpRes.user!.appMetadata['provider'] as String?,
                );
              }
            } catch (_) {}
          }
        }
      } catch (inner) {
        if (inner is Exception && inner.toString().contains('deactivated')) {
          rethrow;
        }
      }

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
  Future<void> signInWithGoogle() async {
    try {
      // Initiate Supabase OAuth flow with Google
      // On success, the deep link callback will trigger authStateChanges
      // which AuthBloc is listening to.
      final bool launched = await _supabaseClient.auth.signInWithOAuth(
        supabase.OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );

      if (!launched) {
        throw Exception('Google authentication failed to launch.');
      }
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
      return AppUser(
        id: user.id, 
        email: user.email ?? '',
        authProvider: user.appMetadata['provider'] as String?,
      );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _supabaseClient.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      if (user == null) return null;
        return AppUser(
        id: user.id, 
        email: user.email ?? '',
        authProvider: user.appMetadata['provider'] as String?,
      );
    });
  }
}
