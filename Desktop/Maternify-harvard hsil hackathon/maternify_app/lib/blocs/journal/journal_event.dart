part of 'journal_bloc.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();
  @override
  List<Object?> get props => [];
}

class JournalLoadRequested extends JournalEvent {
  final String patientId;
  const JournalLoadRequested({required this.patientId});
  @override
  List<Object?> get props => [patientId];
}

class JournalEntrySubmitted extends JournalEvent {
  final String patientId;
  final String entryText;
  const JournalEntrySubmitted({required this.patientId, required this.entryText});
  @override
  List<Object?> get props => [patientId, entryText];
}
