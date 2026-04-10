import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';
import 'booking_screen.dart';

class SpecialistProfileScreen extends StatelessWidget {
  final DemoSpecialist specialist;

  const SpecialistProfileScreen({super.key, required this.specialist});

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _HeroAppBar(specialist: specialist, en: en, repository: repository),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Info cards row
                    Row(
                      children: [
                        _InfoPill(
                          icon: Icons.language_rounded,
                          label: specialist.displayLanguages(en).join(', '),
                        ),
                        const SizedBox(width: 8),
                        _InfoPill(
                          icon: specialist.hasOnlineConsultation
                              ? Icons.videocam_rounded
                              : Icons.location_city_rounded,
                          label: specialist.hasOnlineConsultation
                              ? L.t(en, 'অনলাইন উপলব্ধ', 'Online available')
                              : L.t(en, 'সশরীরে পরামর্শ', 'In-person only'),
                          color: specialist.hasOnlineConsultation
                              ? const Color(0xFF0F6E56)
                              : const Color(0xFF5D53B7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Chamber / Location
                    _SectionCard(
                      title: L.t(en, 'চেম্বার ও হাসপাতাল', 'Chamber & Hospital'),
                      child: Column(
                        children: [
                          _LocationRow(
                            icon: Icons.local_hospital_outlined,
                            title: specialist.displayHospital(en),
                            subtitle: specialist.displayAddress(en),
                          ),
                          if (specialist.chamberBn != specialist.hospitalBn)
                            _LocationRow(
                              icon: Icons.meeting_room_outlined,
                              title: specialist.displayChamber(en),
                              subtitle: specialist.displayDistance(en),
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Available slots
                    _SectionCard(
                      title: L.t(en, 'পরবর্তী উপলব্ধ সময়', 'Next Available Slots'),
                      child: Column(
                        children: [
                          ...specialist.displaySlots(en).asMap().entries.map(
                                (entry) => _SlotRow(
                                  slot: entry.value,
                                  index: entry.key,
                                  isOnlineSlot: entry.key == 0 &&
                                      specialist.hasOnlineConsultation,
                                  en: en,
                                  onBook: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BookingScreen(
                                        specialist: specialist,
                                        slotIndex: entry.key,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Visit checklist
                    _SectionCard(
                      title: L.t(en, 'সাথে আনুন', 'What to Bring'),
                      child: Column(
                        children: specialist
                            .displayChecklist(en)
                            .asMap()
                            .entries
                            .map(
                              (entry) => _ChecklistRow(
                                item: entry.value,
                                isLast: entry.key ==
                                    specialist.displayChecklist(en).length - 1,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Recent vitals preview
                    _VitalsShareCard(
                      repository: repository,
                      en: en,
                    ),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomBookBar(
            specialist: specialist,
            en: en,
          ),
        );
      },
    );
  }
}

// ── Hero app bar ─────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  final DemoSpecialist specialist;
  final bool en;
  final DemoRepository repository;

  const _HeroAppBar({
    required this.specialist,
    required this.en,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      actions: [
        IconButton(
          tooltip: en ? 'বাংলা' : 'English',
          onPressed: repository.toggleLanguage,
          icon: const Icon(Icons.translate_rounded),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B2E50), Color(0xFFB44C71)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        specialist.avatarInitials,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialist.displayName(en),
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialist.displaySpecialty(en),
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            L.t(en, 'পরামর্শ ফি: ৳${specialist.fee}',
                                'Consultation fee: ৳${specialist.fee}'),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom book bar ───────────────────────────────────────────────────────────

class _BottomBookBar extends StatelessWidget {
  final DemoSpecialist specialist;
  final bool en;

  const _BottomBookBar({required this.specialist, required this.en});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border:
            Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (specialist.hasOnlineConsultation) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingScreen(
                      specialist: specialist,
                      slotIndex: 0,
                      forceOnline: true,
                    ),
                  ),
                ),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: Text(
                  L.t(en, 'অনলাইন', 'Online'),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F6E56),
                  side: const BorderSide(color: Color(0xFF0F6E56)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      BookingScreen(specialist: specialist, slotIndex: 0),
                ),
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(
                L.t(en, 'অ্যাপয়েন্টমেন্ট বুক করুন', 'Book Appointment'),
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF8B2E50),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                    fontSize: 12.5, color: color, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  const _LocationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF8B2E50).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF8B2E50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF6C6068),
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String slot;
  final int index;
  final bool isOnlineSlot;
  final bool en;
  final VoidCallback onBook;

  const _SlotRow({
    required this.slot,
    required this.index,
    required this.isOnlineSlot,
    required this.en,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: index < 3 ? 8 : 0),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 16, color: Color(0xFF9C8D96)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slot,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
          if (isOnlineSlot)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
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
            ),
          TextButton(
            onPressed: onBook,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B2E50),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              L.t(en, 'বুক করুন', 'Book'),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String item;
  final bool isLast;

  const _ChecklistRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF5D53B7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded,
                size: 16, color: Color(0xFF5D53B7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _VitalsShareCard extends StatelessWidget {
  final DemoRepository repository;
  final bool en;

  const _VitalsShareCard({required this.repository, required this.en});

  @override
  Widget build(BuildContext context) {
    final latest = repository.latestVitals;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share_rounded,
                    size: 18, color: Color(0xFF8B2E50)),
                const SizedBox(width: 8),
                Text(
                  L.t(en, 'সাম্প্রতিক স্বাস্থ্য তথ্য শেয়ার করুন',
                      'Share Recent Health Data'),
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              L.t(
                en,
                'বুকিংয়ের সময় আপনার সর্বশেষ রিডিং বিশেষজ্ঞের কাছে পাঠানো হবে।',
                'Your latest readings will be sent to the specialist when you book.',
              ),
              style: GoogleFonts.nunito(
                  color: const Color(0xFF675A63), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _VitalChip(
                    label: 'BP',
                    value:
                        '${latest.systolicBp}/${latest.diastolicBp} mmHg'),
                const SizedBox(width: 8),
                _VitalChip(
                    label: L.t(en, 'কিক', 'Kick'),
                    value: '${latest.kickCount}/2h'),
                const SizedBox(width: 8),
                _VitalChip(
                    label: L.t(en, 'ওজন', 'Weight'),
                    value: '${latest.weightKg.toStringAsFixed(1)} kg'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: switch (repository.currentRiskLevel) {
                      DemoRiskLevel.green =>
                        const Color(0xFF197A5B).withValues(alpha: 0.1),
                      DemoRiskLevel.yellow =>
                        const Color(0xFFB17616).withValues(alpha: 0.1),
                      DemoRiskLevel.red =>
                        const Color(0xFFD1423B).withValues(alpha: 0.1),
                    },
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${L.t(en, 'ঝুঁকি', 'Risk')}: ${repository.riskLabel}',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: switch (repository.currentRiskLevel) {
                        DemoRiskLevel.green => const Color(0xFF197A5B),
                        DemoRiskLevel.yellow => const Color(0xFFB17616),
                        DemoRiskLevel.red => const Color(0xFFD1423B),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;

  const _VitalChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: const Color(0xFF786B72))),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
