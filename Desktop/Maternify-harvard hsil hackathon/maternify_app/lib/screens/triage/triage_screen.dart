import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../demo/demo_repository.dart';
import '../../models/triage_event.dart';
import '../../utils/l10n.dart';

class TriageScreen extends StatefulWidget {
  final String patientId;

  const TriageScreen({super.key, required this.patientId});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final DemoRepository _repository = DemoRepository.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  String _language = 'bn';

  static const List<String> _starterChipsBn = [
    'মাথা ঘুরছে আর চোখে ঝাপসা দেখছি',
    'আজকে হাত পা একটু ফুলে গেছে',
    'শিশুর নড়াচড়া কম লাগছে',
  ];

  static const List<String> _starterChipsEn = [
    'I have dizziness and blurred vision',
    'My hands and feet are swollen today',
    'I feel reduced fetal movement',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitText(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    _textController.clear();

    try {
      await _repository.submitTriage(
        patientId: widget.patientId,
        text: text,
        lang: _language,
      );
      _jumpToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = _repository;
    final en = repository.isEnglish;
    final latest = repository.latestVitals;
    final chips = en ? _starterChipsEn : _starterChipsBn;
    return Scaffold(
      appBar: AppBar(
        title: Text(L.t(en, 'লক্ষণ বিশ্লেষণ', 'Symptom Analysis')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _language,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: const Color(0xFF993556),
                iconEnabledColor: Colors.white,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                items: const [
                  DropdownMenuItem(value: 'bn', child: Text('Bangla')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) => setState(() => _language = value ?? 'bn'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF6EEF1),
              border: Border(bottom: BorderSide(color: Color(0xFFEADADF))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.t(en, 'সাম্প্রতিক স্বাস্থ্য তথ্য', 'Recent Health Context'),
                  style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  L.t(en,
                    'সর্বশেষ BP ${latest.systolicBp}/${latest.diastolicBp} • কিক ${latest.kickCount} • ঝুঁকি: ${repository.riskLabelBangla}',
                    'Latest BP ${latest.systolicBp}/${latest.diastolicBp} • Kick ${latest.kickCount} • Risk: ${repository.riskLabel}',
                  ),
                  style: GoogleFonts.nunito(color: const Color(0xFF665A62)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map(
                        (chip) => ActionChip(
                          label: Text(chip),
                          onPressed: () => _submitText(chip),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: repository,
              builder: (context, _) {
                final messages = repository.chatMessages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (_isSubmitting ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const _TypingBubble();
                    }
                    final message = messages[index];
                    return _ChatBubble(message: message);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submitText,
                      decoration: InputDecoration(
                        hintText: _language == 'bn'
                            ? 'লক্ষণ লিখুন... যেমন: মাথা ঘুরছে'
                            : 'Describe symptoms...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitText(_textController.text),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final DemoChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF993556) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  height: 1.45,
                  color: isUser ? Colors.white : const Color(0xFF322730),
                ),
              ),
            ),
            if (!isUser && message.tier != null) ...[
              const SizedBox(height: 6),
              _SeverityCard(
                tier: message.tier!,
                escalationRequired: message.escalationRequired,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityCard extends StatelessWidget {
  final TriageTier tier;
  final bool escalationRequired;

  const _SeverityCard({
    required this.tier,
    required this.escalationRequired,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      TriageTier.green => const Color(0xFF197A5B),
      TriageTier.yellow => const Color(0xFFB17616),
      TriageTier.red => const Color(0xFFD1423B),
    };
    final en = DemoRepository.instance.isEnglish;
    final title = en
        ? switch (tier) {
            TriageTier.green => 'Green • Self-care at home',
            TriageTier.yellow => 'Yellow • Contact clinic today',
            TriageTier.red => 'Red • Seek urgent care now',
          }
        : switch (tier) {
            TriageTier.green => 'সবুজ • ঘরেই যত্ন নিন',
            TriageTier.yellow => 'হলুদ • ক্লিনিকে যোগাযোগ করুন',
            TriageTier.red => 'লাল • এখনই জরুরি সহায়তা নিন',
          };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            escalationRequired
                ? Icons.emergency_rounded
                : Icons.health_and_safety_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunito(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
              child: const _PulseDot(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF993556),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
