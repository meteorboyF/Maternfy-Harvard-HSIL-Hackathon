part of 'vitals_bloc.dart';

abstract class VitalsState extends Equatable {
  const VitalsState();
  @override
  List<Object?> get props => [];
}

class VitalsInitial extends VitalsState {}
class VitalsLoading extends VitalsState {}

class VitalsLoaded extends VitalsState {
  final List<VitalsLog> logs;
  const VitalsLoaded({required this.logs});
  @override
  List<Object?> get props => [logs];
}

class VitalsError extends VitalsState {
  final String message;
  const VitalsError({required this.message});
  @override
  List<Object?> get props => [message];
}
