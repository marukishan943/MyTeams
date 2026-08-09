import 'package:equatable/equatable.dart';
import '../../domain/entities/app_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial state when the app is bootstrapping.
class AuthInitial extends AuthState {}

/// State representing an active background authentication action (loading indicator).
class AuthLoading extends AuthState {}

/// State indicating the user is successfully authenticated.
class Authenticated extends AuthState {
  final AppUser user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State indicating the user is not authenticated.
class Unauthenticated extends AuthState {}

/// State representing authentication failure (e.g. invalid credentials, network error).
class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State indicating the password reset email/OTP has been sent.
class AuthResetPasswordEmailSent extends AuthState {}

/// State indicating the OTP has been successfully verified.
class AuthOTPVerified extends AuthState {}

/// State indicating the password has been successfully reset.
class AuthPasswordResetSuccess extends AuthState {}

/// State indicating the password has been successfully changed while logged in.
class AuthChangePasswordSuccess extends AuthState {}

