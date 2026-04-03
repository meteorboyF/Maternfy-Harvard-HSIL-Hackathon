part of 'vitals_bloc.dart';

abstract class VitalsEvent extends Equatable {
  const VitalsEvent();
  @override
  List<Object?> get props => [];
}

class VitalsLoadRequested extends VitalsEvent {
  final String patientId;
  const VitalsLoadRequested({required this.patientId});
  @override
  List<Object?> get props => [patientId];
}

class VitalsLogSubmitted extends VitalsEvent {
  final VitalsLog vitals;
  const VitalsLogSubmitted({required this.vitals});
  @override
  List<Object?> get props => [vitals];
}
