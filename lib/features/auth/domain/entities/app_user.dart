import 'package:equatable/equatable.dart';

/// A domain representation of an authenticated user, decoupled from the auth provider.
class AppUser extends Equatable {
  final String id;
  final String email;

  const AppUser({
    required this.id,
    required this.email,
  });

  @override
  List<Object?> get props => [id, email];
}
