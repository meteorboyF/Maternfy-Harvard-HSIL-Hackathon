import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';

class BookingScreen extends StatefulWidget {
  final DemoSpecialist specialist;
  final int slotIndex;
  final bool forceOnline;

  const BookingScreen({
    super.key,
    required this.specialist,
    required this.slotIndex,
    this.forceOnline = false,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late int _selectedSlot;
  late bool _isOnline;
  bool _shareVitals = true;
  bool _isLoading = false;
  DemoAppointment? _confirmedAppointment;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.slotIndex;
    _isOnline = widget.forceOnline ||
        (widget.specialist.availableSlotsBn[widget.slotIndex]
            .contains('অনলাইন') ||
            widget.specialist.availableSlotsEn[widget.slotIndex]
                .contains('Online'));
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);
    try {
      final appointment = await DemoRepository.instance.bookAppointment(
        specialist: widget.specialist,
        slotIndex: _selectedSlot,
        isOnline: _isOnline,
        shareVitals: _shareVitals,
      );
      if (mounted) setState(() => _confirmedAppointment = appointment);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;

        if (_confirmedAppointment != null) {
          return _ConfirmationScreen(
            appointment: _confirmedAppointment!,
            specialist: widget.specialist,
            en: en,
            repository: repository,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'অ্যাপয়েন্টমেন্ট বুক করুন',
                'Book Appointment')),
            actions: [
              IconButton(
                tooltip: en ? 'বাংলা' : 'English',
                onPressed: repository.toggleLanguage,
                icon: const Icon(Icons.translate_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              // Specialist summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B2E50), Color(0xFFB44C71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          widget.specialist.avatarInitials,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.specialist.displayName(en),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.specialist.displaySpecialty(en),
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Slot selection
              Text(
                L.t(en, 'সময় বেছে নিন', 'Select a Time Slot'),
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              ...widget.specialist.displaySlots(en).asMap().entries.map(
                    (entry) => _SlotTile(
                      slot: entry.value,
                      index: entry.key,
                      selected: _selectedSlot == entry.key,
                      isOnlineSlot: entry.value.contains('Online') ||
                          entry.value.contains('অনলাইন'),
                      en: en,
                      onTap: () => setState(() {
                        _selectedSlot = entry.key;
                        _isOnline = entry.value.contains('Online') ||
                            entry.value.contains('অনলাইন');
                      }),
                    ),
                  ),
              const SizedBox(height: 20),

              // Visit type
              Text(
                L.t(en, 'পরিদর্শনের ধরন', 'Visit Type'),
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.location_city_rounded,
                      title: L.t(en, 'সশরীরে', 'In-Person'),
                      subtitle: L.t(
                          en,
                          widget.specialist.displayChamber(en),
                          widget.specialist.displayChamber(en)),
                      selected: !_isOnline,
                      onTap: () => setState(() => _isOnline = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (widget.specialist.hasOnlineConsultation)
                    Expanded(
                      child: _TypeCard(
                        icon: Icons.videocam_rounded,
                        title: L.t(en, 'অনলাইন', 'Online'),
                        subtitle: L.t(en, 'ভিডিও কনসালটেশন',
                            'Video consultation'),
                        selected: _isOnline,
                        onTap: () => setState(() => _isOnline = true),
                        color: const Color(0xFF0F6E56),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Fee breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.t(en, 'ফি বিবরণ', 'Fee Breakdown'),
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      _FeeRow(
                        label: L.t(en, 'পরামর্শ ফি', 'Consultation fee'),
                        value: '৳${widget.specialist.fee}',
                      ),
                      _FeeRow(
                        label: L.t(en, 'প্ল্যাটফর্ম সেবা', 'Platform service'),
                        value: '৳0',
                        isZero: true,
                      ),
                      const Divider(height: 20),
                      _FeeRow(
                        label: L.t(en, 'মোট', 'Total'),
                        value: '৳${widget.specialist.fee}',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Share vitals toggle
              Card(
                child: SwitchListTile(
                  value: _shareVitals,
                  onChanged: (val) => setState(() => _shareVitals = val),
                  title: Text(
                    L.t(en, 'সাম্প্রতিক স্বাস্থ্য তথ্য শেয়ার করুন',
                        'Share Recent Health Data'),
                    style:
                        GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    L.t(
                      en,
                      'আপনার BP, কিক কাউন্ট ও ঝুঁকির মাত্রা বিশেষজ্ঞের কাছে পাঠানো হবে।',
                      'Your BP, kick count, and risk level will be sent to the specialist.',
                    ),
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF675A63), fontSize: 13),
                  ),
                  activeThumbColor: const Color(0xFF8B2E50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                  top: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _isLoading ? null : _confirmBooking,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      L.t(en, 'নিশ্চিত করুন', 'Confirm Booking'),
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ── Confirmation screen ───────────────────────────────────────────────────────

class _ConfirmationScreen extends StatelessWidget {
  final DemoAppointment appointment;
  final DemoSpecialist specialist;
  final bool en;
  final DemoRepository repository;

  const _ConfirmationScreen({
    required this.appointment,
    required this.specialist,
    required this.en,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final refId = appointment.id.substring(0, 8).toUpperCase();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF197A5B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 44, color: Color(0xFF197A5B)),
              ),
              const SizedBox(height: 24),
              Text(
                L.t(en, 'বুকিং নিশ্চিত হয়েছে!', 'Booking Confirmed!'),
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                L.t(
                  en,
                  'আপনার অ্যাপয়েন্টমেন্ট বুক হয়েছে। বিশেষজ্ঞ শীঘ্রই নিশ্চিতকরণ পাঠাবেন।',
                  'Your appointment has been booked. The specialist will send a confirmation shortly.',
                ),
                style: GoogleFonts.nunito(
                    color: const Color(0xFF675A63),
                    height: 1.5,
                    fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Booking card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ConfirmRow(
                        label: L.t(en, 'বিশেষজ্ঞ', 'Specialist'),
                        value: appointment.displayName(en),
                      ),
                      _ConfirmRow(
                        label: L.t(en, 'সময়', 'Slot'),
                        value: appointment.displaySlot(en),
                      ),
                      _ConfirmRow(
                        label: L.t(en, 'ধরন', 'Type'),
                        value: appointment.isOnline
                            ? L.t(en, 'অনলাইন পরামর্শ', 'Online Consultation')
                            : L.t(en, 'সশরীরে পরামর্শ', 'In-Person Visit'),
                      ),
                      if (appointment.vitalsShared)
                        _ConfirmRow(
                          label: L.t(en, 'স্বাস্থ্য তথ্য', 'Health Data'),
                          value: L.t(
                              en, 'শেয়ার করা হয়েছে ✓', 'Shared with doctor ✓'),
                          valueColor: const Color(0xFF197A5B),
                        ),
                      _ConfirmRow(
                        label: L.t(en, 'রেফারেন্স', 'Reference'),
                        value: '#$refId',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (appointment.vitalsShared) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D53B7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            const Color(0xFF5D53B7).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded,
                          size: 18, color: Color(0xFF5D53B7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          L.t(
                            en,
                            'BP ${repository.latestVitals.systolicBp}/${repository.latestVitals.diastolicBp} mmHg, risk level, and triage summary sent to ${appointment.displayName(en)}.',
                            'BP ${repository.latestVitals.systolicBp}/${repository.latestVitals.diastolicBp} mmHg, ঝুঁকির মাত্রা ও লক্ষণ সারসংক্ষেপ ${appointment.displayName(en)}-এর কাছে পাঠানো হয়েছে।',
                          ),
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: const Color(0xFF5D53B7),
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Spacer(),

              // Done button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Pop back to home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2E50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    L.t(en, 'হোমে ফিরুন', 'Back to Home'),
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.nunito(
                  color: const Color(0xFF675A63), fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking sub-widgets ───────────────────────────────────────────────────────

class _SlotTile extends StatelessWidget {
  final String slot;
  final int index;
  final bool selected;
  final bool isOnlineSlot;
  final bool en;
  final VoidCallback onTap;

  const _SlotTile({
    required this.slot,
    required this.index,
    required this.selected,
    required this.isOnlineSlot,
    required this.en,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF8B2E50).withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF8B2E50)
                  : Colors.grey.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFF8B2E50)
                    : const Color(0xFF9C8D96),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slot,
                  style: GoogleFonts.nunito(
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (isOnlineSlot)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6E56).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    L.t(en, 'অনলাইন', 'Online'),
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFF0F6E56),
                        fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF8B2E50),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.grey.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : const Color(0xFF9C8D96)),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: selected ? color : null,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: const Color(0xFF786B72)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isZero;

  const _FeeRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              color: isBold ? null : const Color(0xFF675A63),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: isZero
                  ? const Color(0xFF197A5B)
                  : isBold
                      ? const Color(0xFF8B2E50)
                      : null,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
