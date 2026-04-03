import 'package:equatable/equatable.dart';

enum TriageTier { green, yellow, red }

class TriageEvent extends Equatable {
  final String id;
  final String patientId;
  final String inputText;
  final String inputLang;
  final TriageTier triageTier;
  final String adviceBangla;
  final String adviceEnglish;
  final bool escalationRequired;
  final String suggestedAction;
  final DateTime createdAt;

  const TriageEvent({
    required this.id,
    required this.patientId,
    required this.inputText,
    required this.inputLang,
    required this.triageTier,
    required this.adviceBangla,
    required this.adviceEnglish,
    required this.escalationRequired,
    required this.suggestedAction,
    required this.createdAt,
  });

  factory TriageEvent.fromJson(Map<String, dynamic> json) => TriageEvent(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        inputText: json['input_text'] as String,
        inputLang: json['input_lang'] as String,
        triageTier: TriageTier.values.firstWhere(
          (e) => e.name == json['triage_tier'],
          orElse: () => TriageTier.green,
        ),
        adviceBangla: json['advice_bangla'] as String,
        adviceEnglish: json['advice_english'] as String,
        escalationRequired: json['escalation_required'] as bool,
        suggestedAction: json['suggested_action'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id];
}
