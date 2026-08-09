import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if the user is already logged in (checked during splash screen).
class AuthCheckRequested extends AuthEvent {}

/// Request login with email and password.
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Request signup with email and password.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Request signout.
class AuthSignOutRequested extends AuthEvent {}

/// Request password reset email/OTP.
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Request OTP verification for recovery.
class AuthOTPVerificationRequested extends AuthEvent {
  final String email;
  final String token;

  const AuthOTPVerificationRequested({required this.email, required this.token});

  @override
  List<Object?> get props => [email, token];
}

/// Submit the final password reset.
class AuthPasswordResetSubmitted extends AuthEvent {
  final String newPassword;

  const AuthPasswordResetSubmitted({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}
