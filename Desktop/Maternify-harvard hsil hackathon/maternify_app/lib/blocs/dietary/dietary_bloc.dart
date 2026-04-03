import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

part 'dietary_event.dart';
part 'dietary_state.dart';

class DietaryBloc extends Bloc<DietaryEvent, DietaryState> {
  DietaryBloc() : super(DietaryInitial()) {
    on<DietaryQuerySubmitted>(_onQuery);
  }

  Future<void> _onQuery(
      DietaryQuerySubmitted event, Emitter<DietaryState> emit) async {
    final currentHistory = state is DietaryLoaded
        ? List<DietaryMessage>.from((state as DietaryLoaded).history)
        : state is DietaryError
            ? List<DietaryMessage>.from((state as DietaryError).history)
            : <DietaryMessage>[];

    emit(DietaryLoading());
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) ApiService.setAuthToken(token);

      final response = await ApiService.client.post(
        '/dietary',
        data: {
          'patient_id': event.patientId,
          'query': event.query,
        },
      );

      final msg = DietaryMessage.fromJson(
        response.data as Map<String, dynamic>,
        event.query,
      );

      emit(DietaryLoaded(history: [...currentHistory, msg]));
    } catch (e) {
      emit(DietaryError(
        message: e.toString(),
        history: currentHistory,
      ));
    }
  }
}
