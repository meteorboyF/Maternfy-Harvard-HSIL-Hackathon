import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

part 'journal_event.dart';
part 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc() : super(JournalInitial()) {
    on<JournalLoadRequested>(_onLoad);
    on<JournalEntrySubmitted>(_onSubmit);
  }

  Future<void> _onLoad(
      JournalLoadRequested event, Emitter<JournalState> emit) async {
    emit(JournalLoading());
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) ApiService.setAuthToken(token);

      final response = await ApiService.client
          .get('/journal/${event.patientId}', queryParameters: {'limit': '20'});

      final entries = (response.data as List)
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(JournalLoaded(history: entries));
    } catch (e) {
      emit(JournalError(message: e.toString()));
    }
  }

  Future<void> _onSubmit(
      JournalEntrySubmitted event, Emitter<JournalState> emit) async {
    final currentHistory = state is JournalLoaded
        ? (state as JournalLoaded).history
        : state is JournalError
            ? (state as JournalError).history
            : <JournalEntry>[];

    emit(JournalSubmitting(history: currentHistory));
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) ApiService.setAuthToken(token);

      final response = await ApiService.client.post('/journal', data: {
        'patient_id': event.patientId,
        'entry_text': event.entryText,
      });

      final entry =
          JournalEntry.fromJson(response.data as Map<String, dynamic>);
      emit(JournalLoaded(
        history: [entry, ...currentHistory],
        latest: entry,
      ));
    } catch (e) {
      emit(JournalError(message: e.toString(), history: currentHistory));
    }
  }
}
