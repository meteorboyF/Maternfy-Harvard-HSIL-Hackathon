part of 'dietary_bloc.dart';

abstract class DietaryEvent extends Equatable {
  const DietaryEvent();
  @override
  List<Object?> get props => [];
}

class DietaryQuerySubmitted extends DietaryEvent {
  final String patientId;
  final String query;

  const DietaryQuerySubmitted({required this.patientId, required this.query});

  @override
  List<Object?> get props => [patientId, query];
}
