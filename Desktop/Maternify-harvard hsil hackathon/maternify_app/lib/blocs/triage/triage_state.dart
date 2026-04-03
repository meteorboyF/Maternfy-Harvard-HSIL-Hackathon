part of 'triage_bloc.dart';

class TriageMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final TriageTier? triageTier;
  final bool escalationRequired;

  const TriageMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.triageTier,
    this.escalationRequired = false,
  });
}

abstract class TriageState extends Equatable {
  const TriageState();
  @override
  List<Object?> get props => [];
}

class TriageInitial extends TriageState {}

class TriageConversation extends TriageState {
  final List<TriageMessage> messages;
  final bool isLoading;
  const TriageConversation({required this.messages, this.isLoading = false});
  @override
  List<Object?> get props => [messages, isLoading];
}
