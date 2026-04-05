import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../blocs/triage/triage_bloc.dart';
import '../../models/triage_event.dart';

class TriageScreen extends StatelessWidget {
  final String patientId;
  const TriageScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TriageBloc(),
      child: _TriageView(patientId: patientId),
    );
  }
}

class _TriageView extends StatefulWidget {
  final String patientId;
  const _TriageView({required this.patientId});

  @override
  State<_TriageView> createState() => _TriageViewState();
}

class _TriageViewState extends State<_TriageView> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedLang = 'bn';

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<TriageBloc>().add(TriageMessageSent(
      patientId: widget.patientId,
      text: text,
      lang: _selectedLang,
    ));
    _textCtrl.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI ট্রায়াজ', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          // Language toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButton<String>(
              value: _selectedLang,
              dropdownColor: const Color(0xFF993556),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'bn', child: Text('বাংলা', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setState(() => _selectedLang = v ?? 'bn'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: BlocBuilder<TriageBloc, TriageState>(
              builder: (context, state) {
                if (state is TriageInitial) {
                  return _WelcomePrompt(lang: _selectedLang);
                }
                if (state is! TriageConversation) return const SizedBox();

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == state.messages.length) return const _TypingIndicator();
                    return _ChatBubble(message: state.messages[i]);
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(context),
                    decoration: InputDecoration(
                      hintText: _selectedLang == 'bn'
                          ? 'আপনার লক্ষণ লিখুন...'
                          : 'Describe your symptoms...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF993556)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF993556), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<TriageBloc, TriageState>(
                  builder: (ctx, state) {
                    final loading = state is TriageConversation && state.isLoading;
                    return FloatingActionButton.small(
                      onPressed: loading ? null : () => _send(ctx),
                      backgroundColor: const Color(0xFF993556),
                      child: loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePrompt extends StatelessWidget {
  final String lang;
  const _WelcomePrompt({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Color(0xFF993556)),
            const SizedBox(height: 16),
            Text(
              lang == 'bn'
                  ? 'আপনার স্বাস্থ্য সম্পর্কে জিজ্ঞেস করুন\nআমি সাহায্য করব'
                  : 'Ask about your health\nI\'m here to help',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final TriageMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF993556) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.nunito(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            // Triage result card (colored, for AI responses)
            if (!isUser && message.triageTier != null)
              _TriageResultCard(tier: message.triageTier!, escalation: message.escalationRequired),
          ],
        ),
      ),
    );
  }

}

class _TriageResultCard extends StatelessWidget {
  final TriageTier tier;
  final bool escalation;
  const _TriageResultCard({required this.tier, required this.escalation});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (tier) {
      TriageTier.green  => (const Color(0xFF1D9E75), '✓', 'চিন্তার কিছু নেই'),
      TriageTier.yellow => (const Color(0xFFBA7517), '⚠', 'ডাক্তারের সাথে কথা বলুন'),
      TriageTier.red    => (const Color(0xFFE24B4A), '🚨', 'এখনই হাসপাতালে যান'),
    };

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(tier == TriageTier.red ? 0.8 : 0.4),
          width: tier == TriageTier.red ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 200),
            SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: Color(0xFF993556), shape: BoxShape.circle),
        ),
      );
}
