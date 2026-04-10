import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../demo/demo_repository.dart';
import '../../models/patient.dart';
import '../../utils/l10n.dart';

class SosScreen extends StatefulWidget {
  final Patient patient;

  const SosScreen({super.key, required this.patient});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final DemoRepository _repository = DemoRepository.instance;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  bool _isSending = false;
  DemoSosResult? _result;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final en = _repository.isEnglish;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(L.t(en, 'জরুরি সাহায্য পাঠাবেন?', 'Send Emergency Help?')),
            content: Text(
              L.t(en,
                'আপনার সর্বশেষ স্বাস্থ্য তথ্য এখনই ক্লিনিক টিমকে পাঠানো হবে।',
                'Your latest health data will be sent to your clinic team immediately.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(L.t(en, 'বাতিল করুন', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(L.t(en, 'SOS পাঠান', 'Send SOS')),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isSending = true);
    final result = await _repository.triggerSos();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final en = _repository.isEnglish;
    final latest = _repository.latestVitals;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
          children: [
            Text(
              L.t(en, 'জরুরি সাহায্য', 'Emergency Help'),
              style: GoogleFonts.nunito(
                  fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF4A0C14),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.t(en, 'শুধু জরুরি অবস্থায় ব্যবহার করুন',
                        'For emergencies only'),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.t(en,
                      'আপনার সর্বশেষ স্বাস্থ্য তথ্য এবং অবস্থান ক্লিনিক টিমকে পাঠানো হবে।',
                      'Your latest health data and location will be sent to your clinic team.',
                    ),
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = _result != null
                      ? 1.0
                      : 1 + (_pulseController.value * 0.08);
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: _isSending || _result != null ? null : _confirmAndSend,
                  child: Container(
                    width: 196,
                    height: 196,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _result != null
                          ? const Color(0xFF197A5B)
                          : const Color(0xFFD1423B),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFD1423B).withValues(alpha: 0.26),
                          blurRadius: 28,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _result != null
                                      ? Icons.check_circle_outline
                                      : Icons.sos_rounded,
                                  color: Colors.white,
                                  size: 68,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _result != null
                                      ? L.t(en, 'পাঠানো হয়েছে', 'Sent')
                                      : L.t(en, 'SOS চাপুন', 'Tap SOS'),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_result != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.statusLine,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF197A5B),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_result!.summary,
                        style: GoogleFonts.nunito(height: 1.45)),
                    const SizedBox(height: 12),
                    ..._result!.steps.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check,
                                size: 16, color: Color(0xFF197A5B)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(step, style: GoogleFonts.nunito())),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                L.t(en,
                  'শুধু জরুরি পরিস্থিতিতে এই বোতাম চাপুন।',
                  'Only press this button in a genuine emergency.',
                ),
                style: GoogleFonts.nunito(
                  color: const Color(0xFF6F5E64),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.t(en, 'জরুরি তথ্য', 'Emergency Information'),
                        style: GoogleFonts.nunito(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    _InfoRow(
                        label: L.t(en, 'রোগী', 'Patient'),
                        value: widget.patient.name),
                    _InfoRow(
                        label: L.t(en, 'গর্ভকাল', 'Gestation'),
                        value: L.t(en, '${widget.patient.weeksGestation} সপ্তাহ',
                            '${widget.patient.weeksGestation} weeks')),
                    _InfoRow(
                        label: L.t(en, 'রক্তের গ্রুপ', 'Blood Type'),
                        value: widget.patient.bloodType),
                    _InfoRow(
                        label: L.t(en, 'সর্বশেষ BP', 'Latest BP'),
                        value: '${latest.systolicBp}/${latest.diastolicBp} mmHg'),
                    _InfoRow(
                        label: L.t(en, 'কিক কাউন্ট', 'Kick Count'),
                        value: L.t(en, '২ ঘণ্টায় ${latest.kickCount}',
                            '${latest.kickCount} in 2h')),
                    _InfoRow(
                        label: L.t(en, 'অবস্থান', 'Location'),
                        value: L.t(en, 'ক্লিনিকের সাথে শেয়ার করা হচ্ছে',
                            'Being shared with clinic')),
                    _InfoRow(
                        label: L.t(en, 'জানানো হবে', 'Notifying'),
                        value: L.t(en, 'ক্লিনিক টিম ও জরুরি পরিচিতি',
                            'Clinic team & emergency contact')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: const Color(0xFF796C74),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
