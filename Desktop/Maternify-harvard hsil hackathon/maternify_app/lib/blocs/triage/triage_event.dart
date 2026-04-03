part of 'triage_bloc.dart';

abstract class TriageInputEvent extends Equatable {
  const TriageInputEvent();
  @override
  List<Object?> get props => [];
}

class TriageMessageSent extends TriageInputEvent {
  final String patientId;
  final String text;
  final String lang;
  final String mlRiskTier;

  const TriageMessageSent({
    required this.patientId,
    required this.text,
    this.lang = 'bn',
    this.mlRiskTier = 'green',
  });

  @override
  List<Object?> get props => [patientId, text, lang];
}
