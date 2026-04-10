part of 'journal_bloc.dart';

abstract class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalSubmitting extends JournalState {
  final List<JournalEntry> history;
  const JournalSubmitting({required this.history});
  @override
  List<Object?> get props => [history];
}

class JournalLoaded extends JournalState {
  final List<JournalEntry> history;
  /// The entry that was just analysed (null when only loading history)
  final JournalEntry? latest;

  const JournalLoaded({required this.history, this.latest});

  @override
  List<Object?> get props => [history, latest];
}

class JournalError extends JournalState {
  final String message;
  final List<JournalEntry> history;
  const JournalError({required this.message, this.history = const []});
  @override
  List<Object?> get props => [message];
}

// ─── Data model ───────────────────────────────────────────────────────────────

class JournalEntry {
  final String? id;
  final String entryText;
  final int moodScore;
  final String moodLabel;
  final String moodEmoji;
  final String sentiment;
  final List<String> keyThemes;
  final String responseBangla;
  final String responseEnglish;
  final bool epdsConcern;
  final String copingTipBangla;
  final String copingTipEnglish;
  final DateTime timestamp;

  const JournalEntry({
    this.id,
    required this.entryText,
    required this.moodScore,
    required this.moodLabel,
    required this.moodEmoji,
    required this.sentiment,
    required this.keyThemes,
    required this.responseBangla,
    required this.responseEnglish,
    required this.epdsConcern,
    required this.copingTipBangla,
    required this.copingTipEnglish,
    required this.timestamp,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String?,
        entryText: json['entry_text'] as String? ?? '',
        moodScore: (json['mood_score'] as num?)?.toInt() ?? 5,
        moodLabel: json['mood_label'] as String? ?? 'neutral',
        moodEmoji: json['mood_emoji'] as String? ?? '😐',
        sentiment: json['sentiment'] as String? ?? 'neutral',
        keyThemes: List<String>.from(json['key_themes'] as List? ?? []),
        responseBangla: json['response_bangla'] as String? ?? '',
        responseEnglish: json['response_english'] as String? ?? '',
        epdsConcern: json['epds_concern'] as bool? ?? false,
        copingTipBangla: json['coping_tip_bangla'] as String? ?? '',
        copingTipEnglish: json['coping_tip_english'] as String? ?? '',
        timestamp: json['sent_at'] != null
            ? DateTime.parse(json['sent_at'] as String)
            : DateTime.now(),
      );

  Color get moodColor {
    if (moodScore >= 8) return const Color(0xFF388E3C);
    if (moodScore >= 6) return const Color(0xFF1976D2);
    if (moodScore >= 4) return const Color(0xFFF9A825);
    return const Color(0xFFD32F2F);
  }
}
