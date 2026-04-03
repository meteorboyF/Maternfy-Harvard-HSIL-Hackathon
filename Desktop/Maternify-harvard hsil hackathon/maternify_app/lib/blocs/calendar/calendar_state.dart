part of 'calendar_bloc.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final int weeksGestation;
  final DateTime dueDate;
  final DateTime conceptionDate;
  /// Dates on which vitals were logged (normalised to midnight)
  final Set<DateTime> vitalsDates;
  /// Map of date → highest triage tier recorded that day
  final Map<DateTime, String> triageDates; // 'green' | 'yellow' | 'red'
  final DateTime displayMonth;

  const CalendarLoaded({
    required this.weeksGestation,
    required this.dueDate,
    required this.conceptionDate,
    required this.vitalsDates,
    required this.triageDates,
    required this.displayMonth,
  });

  @override
  List<Object?> get props => [
        weeksGestation,
        dueDate,
        vitalsDates,
        triageDates,
        displayMonth,
      ];

  CalendarLoaded copyWith({DateTime? displayMonth}) => CalendarLoaded(
        weeksGestation: weeksGestation,
        dueDate: dueDate,
        conceptionDate: conceptionDate,
        vitalsDates: vitalsDates,
        triageDates: triageDates,
        displayMonth: displayMonth ?? this.displayMonth,
      );
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError({required this.message});
  @override
  List<Object?> get props => [message];
}
