import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/vitals_log.dart';
import '../../services/supabase_service.dart';

part 'vitals_event.dart';
part 'vitals_state.dart';

class VitalsBloc extends Bloc<VitalsEvent, VitalsState> {
  VitalsBloc() : super(VitalsInitial()) {
    on<VitalsLoadRequested>(_onLoad);
    on<VitalsLogSubmitted>(_onSubmit);
  }

  Future<void> _onLoad(VitalsLoadRequested event, Emitter<VitalsState> emit) async {
    emit(VitalsLoading());
    try {
      final since = DateTime.now().subtract(const Duration(days: 14));
      final data = await SupabaseService.client
          .from('vitals_logs')
          .select()
          .eq('patient_id', event.patientId)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: true);

      final logs = (data as List).map((e) => VitalsLog.fromJson(e)).toList();
      emit(VitalsLoaded(logs: logs));
    } catch (e) {
      emit(VitalsError(message: e.toString()));
    }
  }

  Future<void> _onSubmit(VitalsLogSubmitted event, Emitter<VitalsState> emit) async {
    try {
      await SupabaseService.client.from('vitals_logs').insert(event.vitals.toJson());
      add(VitalsLoadRequested(patientId: event.vitals.patientId));
    } catch (e) {
      emit(VitalsError(message: e.toString()));
    }
  }
}
