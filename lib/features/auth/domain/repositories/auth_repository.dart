import '../entities/app_user.dart';

/// Contract defining the authentication business logic interface.
abstract class AuthRepository {
  /// Sign up a new user using email and password.
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in an existing user using email and password.
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send a password reset email/OTP to the user.
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Verify OTP token sent to the user's email.
  Future<void> verifyOTP({
    required String email,
    required String token,
  });

  /// Update the current user's password to a new one.
  Future<void> resetPassword({
    required String newPassword,
  });

  /// Get the currently authenticated user, or null if none.
  AppUser? get currentUser;

  /// Stream to listen to real-time auth state updates.
  Stream<AppUser?> get authStateChanges;
}
