import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../models/triage_event.dart';
import '../../services/api_service.dart';
import '../../services/firebase_service.dart';

part 'triage_event.dart';
part 'triage_state.dart';

class TriageBloc extends Bloc<TriageInputEvent, TriageState> {
  TriageBloc() : super(TriageInitial()) {
    on<TriageMessageSent>(_onMessageSent);
  }

  Future<void> _onMessageSent(TriageMessageSent event, Emitter<TriageState> emit) async {
    // Append user message immediately
    final current = state is TriageConversation
        ? (state as TriageConversation).messages
        : <TriageMessage>[];

    final userMsg = TriageMessage(text: event.text, isUser: true, timestamp: DateTime.now());
    emit(TriageConversation(messages: [...current, userMsg], isLoading: true));

    try {
      final idToken = await FirebaseService.auth.currentUser?.getIdToken();
      final response = await ApiService.client.post(
        '/triage',
        data: {
          'patient_id': event.patientId,
          'input_text': event.text,
          'input_lang': event.lang,
          'ml_risk_tier': event.mlRiskTier,
        },
        options: Options(headers: {'Authorization': 'Bearer $idToken'}),
      );

      final triageEvent = TriageEvent.fromJson(response.data);
      final botMsg = TriageMessage(
        text: event.lang == 'bn' ? triageEvent.adviceBangla : triageEvent.adviceEnglish,
        isUser: false,
        timestamp: DateTime.now(),
        triageTier: triageEvent.triageTier,
        escalationRequired: triageEvent.escalationRequired,
      );

      final updated = [...(state as TriageConversation).messages, botMsg];
      emit(TriageConversation(messages: updated, isLoading: false));
    } on DioException catch (e) {
      final msgs = (state as TriageConversation).messages;
      emit(TriageConversation(
        messages: [...msgs, TriageMessage(text: 'সংযোগে সমস্যা হয়েছে। আবার চেষ্টা করুন।', isUser: false, timestamp: DateTime.now())],
        isLoading: false,
      ));
    }
  }
}
