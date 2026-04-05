import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final provider = GoogleAuthProvider();
      final credential =
          await FirebaseService.auth.signInWithProvider(provider);
      if (credential.user != null) {
        emit(AuthAuthenticated(user: credential.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      if (credential.user != null) {
        emit(AuthAuthenticated(user: credential.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found'  => 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই',
        'wrong-password'  => 'পাসওয়ার্ড ভুল হয়েছে',
        'invalid-email'   => 'ইমেইল ঠিকানাটি সঠিক নয়',
        'user-disabled'   => 'অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে',
        _                 => e.message ?? 'লগইন ব্যর্থ হয়েছে',
      };
      emit(AuthError(message: msg));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await FirebaseService.auth.signOut();
    emit(AuthUnauthenticated());
  }
}
