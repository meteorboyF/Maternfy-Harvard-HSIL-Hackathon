part of 'calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

class CalendarLoadRequested extends CalendarEvent {
  final String patientId;
  final int weeksGestation;

  const CalendarLoadRequested({
    required this.patientId,
    required this.weeksGestation,
  });

  @override
  List<Object?> get props => [patientId, weeksGestation];
}

class CalendarMonthChanged extends CalendarEvent {
  final DateTime month;
  const CalendarMonthChanged(this.month);

  @override
  List<Object?> get props => [month];
}
