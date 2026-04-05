import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dietary/dietary_bloc.dart';

// ─── Quick-suggestion chips ───────────────────────────────────────────────────

const _suggestions = [
  'আজকের জন্য খাবার পরামর্শ দিন',
  'আয়রন সমৃদ্ধ কী খাবো?',
  'বমি ভাব কমাতে কী খাবো?',
  'ক্যালসিয়ামের জন্য দেশীয় খাবার',
  'রক্তশূন্যতায় কী খাবো?',
  'ডায়াবেটিসে কী এড়াবো?',
];

// ─── Screen entry point ───────────────────────────────────────────────────────

class DietaryScreen extends StatelessWidget {
  final String patientId;
  final int weeksGestation;

  const DietaryScreen({
    super.key,
    required this.patientId,
    required this.weeksGestation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DietaryBloc(),
      child: _DietaryView(
          patientId: patientId, weeksGestation: weeksGestation),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _DietaryView extends StatefulWidget {
  final String patientId;
  final int weeksGestation;

  const _DietaryView(
      {required this.patientId, required this.weeksGestation});

  @override
  State<_DietaryView> createState() => _DietaryViewState();
}

class _DietaryViewState extends State<_DietaryView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.clear();
    context.read<DietaryBloc>().add(DietaryQuerySubmitted(
          patientId: widget.patientId,
          query: trimmed,
        ));
    Future.delayed(const Duration(milliseconds: 400), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('খাদ্য পরামর্শ'),
        backgroundColor: const Color(0xFF993556),
        foregroundColor: Colors.white,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Week banner
          _WeekBanner(weeksGestation: widget.weeksGestation),

          // Conversation area
          Expanded(
            child: BlocBuilder<DietaryBloc, DietaryState>(
              builder: (context, state) {
                if (state is DietaryInitial) {
                  return _EmptyState(onSuggestion: _submit);
                }
                if (state is DietaryLoading) {
                  final history = <DietaryMessage>[];
                  return _ConversationList(
                    history: history,
                    isLoading: true,
                    scrollController: _scrollController,
                    onSuggestion: _submit,
                  );
                }
                if (state is DietaryLoaded) {
                  return _ConversationList(
                    history: state.history,
                    isLoading: false,
                    scrollController: _scrollController,
                    onSuggestion: _submit,
                  );
                }
                if (state is DietaryError) {
                  return _ConversationList(
                    history: state.history,
                    isLoading: false,
                    scrollController: _scrollController,
                    errorMessage: state.message,
                    onSuggestion: _submit,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Input bar
          _InputBar(controller: _controller, onSubmit: _submit),
        ],
      ),
    );
  }
}

// ─── Week banner ──────────────────────────────────────────────────────────────

class _WeekBanner extends StatelessWidget {
  final int weeksGestation;
  const _WeekBanner({required this.weeksGestation});

  String get _trimesterLabel {
    if (weeksGestation <= 12) return '১ম ত্রৈমাসিক';
    if (weeksGestation <= 27) return '২য় ত্রৈমাসিক';
    return '৩য় ত্রৈমাসিক';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFCE4EC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('🥗', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            'সপ্তাহ $weeksGestation • $_trimesterLabel',
            style: const TextStyle(
                color: Color(0xFFAD1457), fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Text(
            'ব্যক্তিগতকৃত পরামর্শ',
            style: TextStyle(color: Color(0xFFAD1457), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestion;
  const _EmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text('🍱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text(
            'আপনার গর্ভাবস্থার জন্য\nব্যক্তিগতকৃত খাদ্য পরামর্শ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'বাংলাদেশের স্থানীয় খাবার ভিত্তিক পরামর্শ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('প্রশ্ন করুন:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFFFCE4EC),
                      side: const BorderSide(color: Color(0xFF993556)),
                      onPressed: () => onSuggestion(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation list ────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<DietaryMessage> history;
  final bool isLoading;
  final ScrollController scrollController;
  final String? errorMessage;
  final ValueChanged<String> onSuggestion;

  const _ConversationList({
    required this.history,
    required this.isLoading,
    required this.scrollController,
    required this.onSuggestion,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        // Previous messages
        ...history.map((msg) => _MessagePair(msg: msg)),

        // Loading indicator
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('পরামর্শ তৈরি হচ্ছে...',
                    style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),

        // Error
        if (errorMessage != null)
          Card(
            color: const Color(0xFFFFEBEE),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text('⚠ $errorMessage',
                  style: const TextStyle(color: Colors.red)),
            ),
          ),

        // Suggestion chips after each response
        if (history.isNotEmpty && !isLoading) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions
                .take(3)
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFFCE4EC),
                      side: const BorderSide(color: Color(0xFF993556)),
                      onPressed: () => onSuggestion(s),
                    ))
                .toList(),
          ),
        ],

        const SizedBox(height: 60),
      ],
    );
  }
}

// ─── A query + response pair ──────────────────────────────────────────────────

class _MessagePair extends StatelessWidget {
  final DietaryMessage msg;
  const _MessagePair({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User query bubble
        if (msg.query != null) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8, left: 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF993556),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg.query!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],

        // AI response card
        _ResponseCard(msg: msg),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── AI response card ─────────────────────────────────────────────────────────

class _ResponseCard extends StatelessWidget {
  final DietaryMessage msg;
  const _ResponseCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text('Maternify পরামর্শ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text(
                  _timeLabel(msg.timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
            const Divider(height: 16),

            // Bangla advice
            Text(
              msg.adviceBangla,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 4),
            Text(
              msg.adviceEnglish,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54, height: 1.4),
            ),

            // Trimester tip
            if (msg.trimesterTip.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg.trimesterTip,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF4A148C)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Recommended foods
            if (msg.recommendedFoods.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('✅ খান:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF2E7D32))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: msg.recommendedFoods
                    .map((f) => Chip(
                          label:
                              Text(f, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFFE8F5E9),
                          side: const BorderSide(color: Color(0xFF81C784)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],

            // Foods to avoid
            if (msg.foodsToAvoid.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('❌ এড়িয়ে চলুন:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFFC62828))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: msg.foodsToAvoid
                    .map((f) => Chip(
                          label:
                              Text(f, style: const TextStyle(fontSize: 12)),
                          backgroundColor: const Color(0xFFFFEBEE),
                          side: const BorderSide(color: Color(0xFFEF9A9A)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  const _InputBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: onSubmit,
              decoration: InputDecoration(
                hintText: 'খাবার সম্পর্কে প্রশ্ন করুন...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<DietaryBloc, DietaryState>(
            builder: (context, state) {
              final loading = state is DietaryLoading;
              return FloatingActionButton.small(
                onPressed:
                    loading ? null : () => onSubmit(controller.text),
                backgroundColor: const Color(0xFF993556),
                elevation: 0,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
              );
            },
          ),
        ],
      ),
    );
  }
}
