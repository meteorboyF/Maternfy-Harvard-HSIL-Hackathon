import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/journal/journal_bloc.dart';
import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';

// ─── Quick mood prompts ───────────────────────────────────────────────────────

const _prompts = [
  'আজ আমি কেমন অনুভব করছি...',
  'আজকে একটু ক্লান্ত লাগছে...',
  'শিশুর নড়াচড়া অনুভব করে খুশি...',
  'উদ্বেগ লাগছে কারণ...',
  'পরিবারের সাথে সময় কাটিয়ে ভালো লাগল...',
];

const _promptsEn = [
  'Today I feel...',
  'Feeling a little tired today...',
  'Happy to feel the baby moving...',
  'Feeling anxious because...',
  'Enjoyed spending time with family...',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class JournalScreen extends StatelessWidget {
  final String patientId;

  const JournalScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          JournalBloc()..add(JournalLoadRequested(patientId: patientId)),
      child: _JournalView(patientId: patientId),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _JournalView extends StatefulWidget {
  final String patientId;
  const _JournalView({required this.patientId});

  @override
  State<_JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<_JournalView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    context.read<JournalBloc>().add(
          JournalEntrySubmitted(patientId: widget.patientId, entryText: text),
        );
    _tabs.animateTo(1); // jump to history after submit
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DemoRepository.instance,
      builder: (context, _) {
        final en = DemoRepository.instance.isEnglish;
        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'মেজাজ জার্নাল', 'Mood Journal')),
            backgroundColor: const Color(0xFF993556),
            foregroundColor: Colors.white,
            leading: const BackButton(),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,

              tabs: [
                Tab(icon: const Icon(Icons.edit_note), text: L.t(en, 'লিখুন', 'Write')),
                Tab(icon: const Icon(Icons.history), text: L.t(en, 'ইতিহাস', 'History')),
              ],
            ),
          ),
          body: BlocConsumer<JournalBloc, JournalState>(
            listener: (context, state) {
              if (state is JournalLoaded && state.latest != null) {
                if (state.latest!.epdsConcern) {
                  final isEn = DemoRepository.instance.isEnglish;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFD32F2F),
                      duration: const Duration(seconds: 6),
                      content: Text(
                        L.t(isEn,
                          '💙 আপনার অনুভূতি গুরুত্বপূর্ণ। আপনার ডাক্তারের সাথে কথা বলুন।',
                          '💙 Your feelings matter. Please speak with your doctor.'),
                      ),
                      action: SnackBarAction(
                        label: L.t(isEn, 'ঠিক আছে', 'OK'),
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              return TabBarView(
                controller: _tabs,
                children: [
                  _WriteTab(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmit: _submit,
                    onPrompt: (p) => setState(() {
                      _controller.text = p;
                      _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length));
                    }),
                    isSubmitting: state is JournalSubmitting,
                    latestEntry:
                        state is JournalLoaded ? state.latest : null,
                    en: en,
                  ),
                  _HistoryTab(state: state, en: en),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Write tab ────────────────────────────────────────────────────────────────

class _WriteTab extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onPrompt;
  final bool isSubmitting;
  final JournalEntry? latestEntry;
  final bool en;

  const _WriteTab({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onPrompt,
    required this.isSubmitting,
    required this.en,
    this.latestEntry,
  });

  @override
  Widget build(BuildContext context) {
    final prompts = en ? _promptsEn : _prompts;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date header
          Row(
            children: [
              const Icon(Icons.today, size: 16, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'en').format(DateTime.now()),
                style:
                    const TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Text entry area
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF993556).withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 7,
              minLines: 5,
              decoration: InputDecoration(
                hintText: L.t(en,
                  'আজকের অনুভূতি লিখুন... আপনি কেমন আছেন?',
                  'Write today\'s feelings... how are you?'),
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
              ),
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
          const SizedBox(height: 10),

          // Quick prompt chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: prompts
                .map((p) => ActionChip(
                      label: Text(p,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFAD1457))),
                      backgroundColor: const Color(0xFFFCE4EC),
                      side: BorderSide.none,
                      onPressed: () => onPrompt(p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          // Submit button
          FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF993556),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.psychology, color: Colors.white),
            label: Text(
              L.t(en,
                isSubmitting ? 'বিশ্লেষণ হচ্ছে...' : 'AI বিশ্লেষণ করুন',
                isSubmitting ? 'Analysing...' : 'Analyse with AI'),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),

          // Latest analysis response card
          if (latestEntry != null) ...[
            const SizedBox(height: 20),
            _ResponseCard(entry: latestEntry!, en: en),
          ],
        ],
      ),
    );
  }
}

// ─── AI response card ─────────────────────────────────────────────────────────

class _ResponseCard extends StatelessWidget {
  final JournalEntry entry;
  final bool en;
  const _ResponseCard({required this.entry, required this.en});

  @override
  Widget build(BuildContext context) {
    final copingTip = en ? entry.copingTipEnglish : entry.copingTipBangla;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: mood score + emoji
            Row(
              children: [
                Text(entry.moodEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _moodLabel(en, entry.moodLabel),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                // Mood score gauge
                _MoodScoreChip(score: entry.moodScore, color: entry.moodColor),
              ],
            ),
            const SizedBox(height: 12),

            // Score bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: entry.moodScore / 10,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(entry.moodColor),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // AI supportive response
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFF993556), size: 16),
                const SizedBox(width: 6),
                Text(L.t(en, 'Maternify বলছে', 'Maternify says'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              en ? entry.responseEnglish : entry.responseBangla,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),

            // Coping tip
            if (copingTip.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        copingTip,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Key themes
            if (entry.keyThemes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.keyThemes
                    .map((t) => Chip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFF3E5F5),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],

            // EPDS concern banner
            if (entry.epdsConcern) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFD32F2F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        L.t(en,
                          'আপনার ডাক্তারের সাথে এই অনুভূতি নিয়ে কথা বলুন।',
                          'Please discuss these feelings with your doctor.'),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _moodLabel(bool isEn, String label) => isEn
      ? label
      : switch (label) {
          'joyful' => 'আনন্দিত',
          'content' => 'সন্তুষ্ট',
          'anxious' => 'উদ্বিগ্ন',
          'sad' => 'দুঃখিত',
          'overwhelmed' => 'অভিভূত',
          'fearful' => 'ভীত',
          'angry' => 'রাগান্বিত',
          'hopeful' => 'আশাবাদী',
          _ => label,
        };
}

class _MoodScoreChip extends StatelessWidget {
  final int score;
  final Color color;
  const _MoodScoreChip({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$score / 10',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ─── History tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final JournalState state;
  final bool en;
  const _HistoryTab({required this.state, required this.en});

  @override
  Widget build(BuildContext context) {
    if (state is JournalLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final history = switch (state) {
      JournalLoaded s => s.history,
      JournalSubmitting s => s.history,
      JournalError s => s.history,
      _ => <JournalEntry>[],
    };

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              L.t(en,
                'এখনো কোনো জার্নাল নেই।\nপ্রথম এন্ট্রি লিখুন!',
                'No journal entries yet.\nWrite your first entry!'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    // Mood trend summary strip
    return Column(
      children: [
        if (history.length >= 3) _MoodTrendStrip(history: history, en: en),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _HistoryCard(entry: history[i], en: en),
          ),
        ),
      ],
    );
  }
}

// ─── Mood trend strip ─────────────────────────────────────────────────────────

class _MoodTrendStrip extends StatelessWidget {
  final List<JournalEntry> history;
  final bool en;
  const _MoodTrendStrip({required this.history, required this.en});

  @override
  Widget build(BuildContext context) {
    final recent = history.take(7).toList().reversed.toList();
    final avg = recent.map((e) => e.moodScore).reduce((a, b) => a + b) /
        recent.length;

    return Container(
      color: const Color(0xFFFCE4EC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '${L.t(en, 'গড় মেজাজ:', 'Avg mood:')} ${avg.toStringAsFixed(1)} / 10',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFAD1457),
                fontSize: 13),
          ),
          const Spacer(),
          ...recent.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(e.moodEmoji,
                    style: const TextStyle(fontSize: 18)),
              )),
        ],
      ),
    );
  }
}

// ─── History entry card ───────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final JournalEntry entry;
  final bool en;
  const _HistoryCard({required this.entry, required this.en});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(entry.moodEmoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _moodLabel(en, entry.moodLabel),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        DateFormat('d MMM, h:mm a', 'en')
                            .format(entry.timestamp),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                _MoodScoreChip(score: entry.moodScore, color: entry.moodColor),
              ],
            ),
            const SizedBox(height: 8),
            // Entry text preview
            Text(
              entry.entryText.length > 120
                  ? '${entry.entryText.substring(0, 120)}...'
                  : entry.entryText,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4),
            ),
            // Themes
            if (entry.keyThemes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: entry.keyThemes
                    .map((t) => Chip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 10)),
                          backgroundColor: const Color(0xFFF3E5F5),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (entry.epdsConcern)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 14, color: Color(0xFFD32F2F)),
                    const SizedBox(width: 4),
                    Text(
                      L.t(en,
                        'মানসিক স্বাস্থ্য পরামর্শ প্রয়োজন',
                        'Mental health support recommended'),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFD32F2F)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _moodLabel(bool isEn, String label) => isEn
      ? label
      : switch (label) {
          'joyful' => 'আনন্দিত',
          'content' => 'সন্তুষ্ট',
          'anxious' => 'উদ্বিগ্ন',
          'sad' => 'দুঃখিত',
          'overwhelmed' => 'অভিভূত',
          'fearful' => 'ভীত',
          'angry' => 'রাগান্বিত',
          'hopeful' => 'আশাবাদী',
          _ => label,
        };
}
