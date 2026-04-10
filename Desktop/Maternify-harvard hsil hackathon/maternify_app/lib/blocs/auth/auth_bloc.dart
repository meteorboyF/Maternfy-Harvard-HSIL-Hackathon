import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../demo/demo_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final session = await DemoRepository.instance.restoreSession();
    if (session == null) {
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthAuthenticated(user: session));
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future<void>.delayed(const Duration(milliseconds: 700));
    emit(const AuthError(
      message:
          'ইমেইল এবং পাসওয়ার্ড দিয়ে সাইন ইন করুন।',
    ));
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final session = await DemoRepository.instance.signIn(
        email: event.email,
        password: event.password,
        selectedRole: event.role,
      );
      emit(AuthAuthenticated(user: session));
    } catch (error) {
      emit(
          AuthError(message: error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await DemoRepository.instance.signOut();
    emit(AuthUnauthenticated());
  }
}
