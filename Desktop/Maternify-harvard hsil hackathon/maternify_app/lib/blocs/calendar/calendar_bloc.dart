import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/supabase_service.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

const _tierRank = {'green': 0, 'yellow': 1, 'red': 2};

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc() : super(CalendarInitial()) {
    on<CalendarLoadRequested>(_onLoad);
    on<CalendarMonthChanged>(_onMonthChanged);
  }

  Future<void> _onLoad(
      CalendarLoadRequested event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      final today = DateTime.now();
      final conceptionDate = today.subtract(
          Duration(days: event.weeksGestation * 7));
      final dueDate = conceptionDate.add(const Duration(days: 280));

      // Load vitals dates (all time for this patient)
      final vitalsData = await SupabaseService.client
          .from('vitals_logs')
          .select('logged_at')
          .eq('patient_id', event.patientId)
          .order('logged_at', ascending: true);

      final vitalsDates = <DateTime>{};
      for (final row in vitalsData as List) {
        final dt = DateTime.parse(row['logged_at'] as String);
        vitalsDates.add(_normalise(dt));
      }

      // Load triage events with tier
      final triageData = await SupabaseService.client
          .from('triage_events')
          .select('created_at, triage_tier')
          .eq('patient_id', event.patientId)
          .order('created_at', ascending: true);

      final triageDates = <DateTime, String>{};
      for (final row in triageData as List) {
        final dt = _normalise(DateTime.parse(row['created_at'] as String));
        final tier = row['triage_tier'] as String;
        final existing = triageDates[dt];
        if (existing == null ||
            (_tierRank[tier] ?? 0) > (_tierRank[existing] ?? 0)) {
          triageDates[dt] = tier;
        }
      }

      emit(CalendarLoaded(
        weeksGestation: event.weeksGestation,
        dueDate: dueDate,
        conceptionDate: conceptionDate,
        vitalsDates: vitalsDates,
        triageDates: triageDates,
        displayMonth: DateTime(today.year, today.month),
      ));
    } catch (e) {
      emit(CalendarError(message: e.toString()));
    }
  }

  void _onMonthChanged(
      CalendarMonthChanged event, Emitter<CalendarState> emit) {
    final current = state;
    if (current is CalendarLoaded) {
      emit(current.copyWith(displayMonth: event.month));
    }
  }
}
