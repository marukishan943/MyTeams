import 'package:equatable/equatable.dart';

/// A domain representation of an authenticated user, decoupled from the auth provider.
class AppUser extends Equatable {
  final String id;
  final String email;
  final String? authProvider;

  const AppUser({
    required this.id,
    required this.email,
    this.authProvider,
  });

  bool get isGoogleAuth => authProvider == 'google';

  @override
  List<Object?> get props => [id, email, authProvider];
}
