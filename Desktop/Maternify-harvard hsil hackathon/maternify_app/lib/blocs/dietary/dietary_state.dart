part of 'dietary_bloc.dart';

abstract class DietaryState extends Equatable {
  const DietaryState();
  @override
  List<Object?> get props => [];
}

class DietaryInitial extends DietaryState {}

class DietaryLoading extends DietaryState {}

class DietaryLoaded extends DietaryState {
  final List<DietaryMessage> history;

  const DietaryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class DietaryError extends DietaryState {
  final String message;
  final List<DietaryMessage> history;

  const DietaryError({required this.message, this.history = const []});

  @override
  List<Object?> get props => [message];
}

// ─── In-memory message model ──────────────────────────────────────────────────

class DietaryMessage {
  final String? query;           // null for the initial tip card
  final String adviceBangla;
  final String adviceEnglish;
  final List<String> recommendedFoods;
  final List<String> foodsToAvoid;
  final String trimesterTip;
  final DateTime timestamp;

  const DietaryMessage({
    this.query,
    required this.adviceBangla,
    required this.adviceEnglish,
    required this.recommendedFoods,
    required this.foodsToAvoid,
    required this.trimesterTip,
    required this.timestamp,
  });

  factory DietaryMessage.fromJson(Map<String, dynamic> json, String query) =>
      DietaryMessage(
        query: query,
        adviceBangla: json['advice_bangla'] as String? ?? '',
        adviceEnglish: json['advice_english'] as String? ?? '',
        recommendedFoods:
            List<String>.from(json['recommended_foods'] as List? ?? []),
        foodsToAvoid:
            List<String>.from(json['foods_to_avoid'] as List? ?? []),
        trimesterTip: json['trimester_tip'] as String? ?? '',
        timestamp: DateTime.now(),
      );
}
