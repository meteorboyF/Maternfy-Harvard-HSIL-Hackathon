part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthEmailSignInRequested extends AuthEvent {
  final String email;
  final String password;
  final DemoRole role;

  const AuthEmailSignInRequested({
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, role];
}
