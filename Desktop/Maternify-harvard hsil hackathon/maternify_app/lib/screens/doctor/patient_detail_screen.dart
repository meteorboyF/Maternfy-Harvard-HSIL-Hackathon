import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../demo/demo_repository.dart';
import '../../models/vitals_log.dart';
import '../../utils/l10n.dart';

class DoctorPatientDetailScreen extends StatelessWidget {
  final DemoProviderPatient patient;

  const DoctorPatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        final vitals = repository.getPatientVitals(patient.id);
        final triage = repository.getPatientTriageHistory(patient.id);
        final aiSummary = repository.getPatientAiSummary(patient.id);
        final latest = vitals.isNotEmpty ? vitals.last : null;

        final riskColor = switch (patient.riskLevel) {
          DemoRiskLevel.green => const Color(0xFF197A5B),
          DemoRiskLevel.yellow => const Color(0xFFB17616),
          DemoRiskLevel.red => const Color(0xFFD1423B),
        };

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Hero app bar ───────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          riskColor.withValues(alpha: 0.85),
                          riskColor,
                        ],
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
                            // Avatar
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Center(
                                child: Text(
                                  patient.name
                                      .split(' ')
                                      .map((w) => w[0])
                                      .take(2)
                                      .join(),
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 20,
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
                                    patient.name,
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    L.t(en,
                                      '${patient.weeksGestation} সপ্তাহ গর্ভকাল • BP ${patient.latestBp}',
                                      '${patient.weeksGestation} weeks pregnant • BP ${patient.latestBp}',
                                    ),
                                    style: GoogleFonts.nunito(
                                      color: Colors.white.withValues(alpha: 0.9),
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
                                      en
                                          ? switch (patient.riskLevel) {
                                              DemoRiskLevel.green => '🟢 Stable',
                                              DemoRiskLevel.yellow =>
                                                '🟡 Watch Closely',
                                              DemoRiskLevel.red =>
                                                '🔴 Urgent',
                                            }
                                          : switch (patient.riskLevel) {
                                              DemoRiskLevel.green =>
                                                '🟢 স্থিতিশীল',
                                              DemoRiskLevel.yellow =>
                                                '🟡 নজরে রাখুন',
                                              DemoRiskLevel.red =>
                                                '🔴 জরুরি মনোযোগ',
                                            },
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
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
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── AI summary ─────────────────────────────────────────
                    _SectionCard(
                      title: L.t(en, 'AI ক্লিনিক্যাল সারসংক্ষেপ',
                          'AI Clinical Summary'),
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF5D53B7),
                      child: Text(
                        aiSummary,
                        style:
                            GoogleFonts.nunito(height: 1.55, fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Latest vitals strip ────────────────────────────────
                    if (latest != null) ...[
                      _SectionCard(
                        title: L.t(en, 'সর্বশেষ ভাইটালস', 'Latest Vitals'),
                        icon: Icons.monitor_heart_rounded,
                        iconColor: const Color(0xFF983755),
                        child: Row(
                          children: [
                            _VitalPill(
                              label: 'BP',
                              value:
                                  '${latest.systolicBp}/${latest.diastolicBp}',
                              unit: 'mmHg',
                              alert: latest.systolicBp >= 140,
                            ),
                            const SizedBox(width: 8),
                            _VitalPill(
                              label: L.t(en, 'কিক', 'Kick'),
                              value: '${latest.kickCount}',
                              unit: L.t(en, '/২ঘ', '/2h'),
                              alert: latest.kickCount <= 9,
                            ),
                            const SizedBox(width: 8),
                            _VitalPill(
                              label: L.t(en, 'গ্লুকোজ', 'Glucose'),
                              value: latest.bloodGlucose.toStringAsFixed(1),
                              unit: 'mmol/L',
                            ),
                            const SizedBox(width: 8),
                            _VitalPill(
                              label: L.t(en, 'ওজন', 'Weight'),
                              value: latest.weightKg.toStringAsFixed(1),
                              unit: 'kg',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── BP trend chart ─────────────────────────────────────
                    if (vitals.length >= 4) ...[
                      _SectionCard(
                        title: L.t(en, 'রক্তচাপের ধারা', 'BP Trend'),
                        icon: Icons.show_chart_rounded,
                        iconColor: const Color(0xFF983755),
                        child: SizedBox(
                            height: 180,
                            child: _PatientBpChart(vitals: vitals)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Triage history ─────────────────────────────────────
                    _SectionCard(
                      title: L.t(
                          en, 'লক্ষণের ইতিহাস', 'Symptom History'),
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF0F6E56),
                      child: triage.isEmpty
                          ? Text(
                              L.t(en, 'কোনো লক্ষণ রেকর্ড নেই।',
                                  'No symptoms recorded.'),
                              style: GoogleFonts.nunito(
                                  color: const Color(0xFF675A63)),
                            )
                          : Column(
                              children: triage.reversed
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) => _TriageRow(
                                        event: entry.value,
                                        isLast: entry.key ==
                                            triage.length - 1,
                                        en: en,
                                      ))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 14),

                    // ── Doctor actions ─────────────────────────────────────
                    _SectionCard(
                      title: L.t(en, 'চিকিৎসক কার্যক্রম',
                          'Doctor Actions'),
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF1F2530),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DoctorActionChip(
                            icon: Icons.flag_rounded,
                            label: L.t(en, 'ঝুঁকি পরিবর্তন',
                                'Override Risk'),
                            color: const Color(0xFFD1423B),
                            onTap: () => _showRiskOverrideSheet(
                                context, patient, en),
                          ),
                          _DoctorActionChip(
                            icon: Icons.medical_services_outlined,
                            label: L.t(
                                en, 'প্রেসক্রিপশন', 'Prescribe'),
                            color: const Color(0xFF0F6E56),
                            onTap: () => _showPrescribeSheet(
                                context, patient, en),
                          ),
                          _DoctorActionChip(
                            icon: Icons.send_rounded,
                            label: L.t(en, 'রেফার করুন',
                                'Refer to Specialist'),
                            color: const Color(0xFF5D53B7),
                            onTap: () => _showReferSheet(
                                context, patient, en),
                          ),
                          _DoctorActionChip(
                            icon: Icons.notifications_active_outlined,
                            label: L.t(en, 'ভাইটালস চাইুন',
                                'Request Vitals'),
                            color: const Color(0xFFB17616),
                            onTap: () async {
                              await DemoRepository.instance
                                  .requestVitals(patient.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(L.t(
                                    en,
                                    'রোগীকে ভাইটালস লগ করতে অনুরোধ পাঠানো হয়েছে।',
                                    'Vitals request sent to patient.',
                                  )),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Logged readings history ────────────────────────────
                    _SectionCard(
                      title:
                          L.t(en, 'সাম্প্রতিক রিডিং', 'Recent Readings'),
                      icon: Icons.list_alt_rounded,
                      iconColor: const Color(0xFF5D53B7),
                      child: Column(
                        children: vitals.reversed
                            .take(5)
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final annotation =
                              repository.getAnnotation(
                                  patient.id, entry.value.loggedAt);
                          return _ReadingRow(
                            log: entry.value,
                            isLast: entry.key == 4 ||
                                entry.key ==
                                    vitals.take(5).length - 1,
                            en: en,
                            annotation: annotation?.annotation,
                            onAnnotate: () =>
                                _showAnnotationSheet(
                                    context,
                                    patient.id,
                                    entry.value.loggedAt,
                                    annotation?.annotation,
                                    en),
                          );
                        }).toList(),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Bottom: Add Note ─────────────────────────────────────────────
          bottomNavigationBar: _AddNoteBar(
            patient: patient,
            en: en,
          ),
        );
      },
    );
  }
}

// ── Add Note bottom bar ───────────────────────────────────────────────────────

class _AddNoteBar extends StatelessWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _AddNoteBar({required this.patient, required this.en});

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
      child: FilledButton.icon(
        onPressed: () => _showNoteSheet(context),
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(
          L.t(en, '${patient.name.split(' ').first}-কে নোট পাঠান',
              'Send Note to ${patient.name.split(' ').first}'),
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1F2530),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }

  void _showNoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NoteSheet(patient: patient, en: en),
    );
  }
}

// ── Note bottom sheet ─────────────────────────────────────────────────────────

class _NoteSheet extends StatefulWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _NoteSheet({required this.patient, required this.en});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    setState(() => _isSending = true);
    await DemoRepository.instance.addDoctorNote(
      patientId: widget.patient.id,
      note: note,
    );
    if (mounted) setState(() { _isSending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'রোগীর জন্য নোট', 'Note for Patient'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            L.t(en,
              'এই নোট ${widget.patient.name}-এর "ক্লিনিক আপডেট" বিভাগে দেখা যাবে।',
              'This note will appear in ${widget.patient.name}\'s Clinic Updates.',
            ),
            style: GoogleFonts.nunito(
                color: const Color(0xFF675A63), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_sent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF197A5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.t(en, 'নোট পাঠানো হয়েছে।', 'Note sent successfully.'),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF197A5B),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: L.t(en,
                  'যেমন: আপনার রক্তচাপ বেশি থাকায় বিশ্রাম নিন এবং পানি বেশি পান করুন।',
                  'e.g. Your BP is elevated — rest and increase fluid intake.',
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2530),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        L.t(en, 'পাঠান', 'Send'),
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── BP chart ──────────────────────────────────────────────────────────────────

class _PatientBpChart extends StatelessWidget {
  final List<VitalsLog> vitals;

  const _PatientBpChart({required this.vitals});

  @override
  Widget build(BuildContext context) {
    final recent = vitals.length > 10 ? vitals.sublist(vitals.length - 10) : vitals;
    final systolic = recent
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.systolicBp.toDouble()))
        .toList();
    final diastolic = recent
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.diastolicBp.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        minY: 65,
        maxY: 160,
        gridData: FlGridData(show: true, horizontalInterval: 15),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: GoogleFonts.nunito(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 3,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= recent.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('d/M').format(recent[i].loggedAt),
                    style: GoogleFonts.nunito(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
                y: 140,
                color: const Color(0xFFD1423B).withValues(alpha: 0.4),
                dashArray: [5, 5]),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: systolic,
            isCurved: true,
            color: const Color(0xFF983755),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: diastolic,
            isCurved: true,
            color: const Color(0xFF5D53B7),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _VitalPill extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool alert;

  const _VitalPill({
    required this.label,
    required this.value,
    required this.unit,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        alert ? const Color(0xFFD1423B) : const Color(0xFF322730);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: alert
              ? const Color(0xFFD1423B).withValues(alpha: 0.08)
              : const Color(0xFFF5F1F3),
          borderRadius: BorderRadius.circular(14),
          border: alert
              ? Border.all(
                  color: const Color(0xFFD1423B).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: const Color(0xFF786B72))),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: color),
            ),
            Text(unit,
                style: GoogleFonts.nunito(
                    fontSize: 10, color: const Color(0xFF9C8D96))),
          ],
        ),
      ),
    );
  }
}

class _TriageRow extends StatelessWidget {
  final DemoTriageEvent event;
  final bool isLast;
  final bool en;

  const _TriageRow(
      {required this.event, required this.isLast, required this.en});

  @override
  Widget build(BuildContext context) {
    final color = switch (event.tier) {
      'red' => const Color(0xFFD1423B),
      'yellow' => const Color(0xFFB17616),
      _ => const Color(0xFF197A5B),
    };
    final tierLabel = en
        ? switch (event.tier) {
            'red' => 'Red',
            'yellow' => 'Yellow',
            _ => 'Green',
          }
        : switch (event.tier) {
            'red' => 'লাল',
            'yellow' => 'হলুদ',
            _ => 'সবুজ',
          };

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chat_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tierLabel,
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM, h:mm a')
                          .format(event.createdAt),
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: const Color(0xFF9C8D96)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"${event.inputText}"',
                  style: GoogleFonts.nunito(
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF655A62),
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  event.displayAdvice(en),
                  style: GoogleFonts.nunito(
                      fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showRiskOverrideSheet(
    BuildContext context, DemoProviderPatient patient, bool en) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RiskOverrideSheet(patient: patient, en: en),
  );
}

void _showPrescribeSheet(
    BuildContext context, DemoProviderPatient patient, bool en) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PrescribeSheet(patient: patient, en: en),
  );
}

void _showReferSheet(
    BuildContext context, DemoProviderPatient patient, bool en) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReferSheet(patient: patient, en: en),
  );
}

void _showAnnotationSheet(BuildContext context, String patientId,
    DateTime loggedAt, String? existing, bool en) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AnnotationSheet(
      patientId: patientId,
      loggedAt: loggedAt,
      existing: existing,
      en: en,
    ),
  );
}

class _DoctorActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DoctorActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Risk override sheet ───────────────────────────────────────────────────────

class _RiskOverrideSheet extends StatefulWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _RiskOverrideSheet({required this.patient, required this.en});

  @override
  State<_RiskOverrideSheet> createState() => _RiskOverrideSheetState();
}

class _RiskOverrideSheetState extends State<_RiskOverrideSheet> {
  DemoRiskLevel? _selected;
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isSaving = true);
    await DemoRepository.instance.overridePatientRisk(
      patientId: widget.patient.id,
      newLevel: _selected!,
      reason: reason,
    );
    if (mounted) setState(() { _isSaving = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'ঝুঁকি স্তর পরিবর্তন', 'Override Risk Level'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            L.t(en, 'রোগী: ${widget.patient.name}',
                'Patient: ${widget.patient.name}'),
            style: GoogleFonts.nunito(
                color: const Color(0xFF675A63), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_saved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF197A5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.t(en, 'ঝুঁকি স্তর আপডেট হয়েছে।',
                          'Risk level updated.'),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF197A5B),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                _RiskChoice(
                  label: L.t(en, 'স্থিতিশীল', 'Stable'),
                  color: const Color(0xFF197A5B),
                  selected: _selected == DemoRiskLevel.green,
                  onTap: () =>
                      setState(() => _selected = DemoRiskLevel.green),
                ),
                const SizedBox(width: 8),
                _RiskChoice(
                  label: L.t(en, 'নজরে', 'Watch'),
                  color: const Color(0xFFB17616),
                  selected: _selected == DemoRiskLevel.yellow,
                  onTap: () =>
                      setState(() => _selected = DemoRiskLevel.yellow),
                ),
                const SizedBox(width: 8),
                _RiskChoice(
                  label: L.t(en, 'জরুরি', 'Urgent'),
                  color: const Color(0xFFD1423B),
                  selected: _selected == DemoRiskLevel.red,
                  onTap: () =>
                      setState(() => _selected = DemoRiskLevel.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: L.t(en, 'কারণ লিখুন…',
                    'Reason for override…'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isSaving ||
                        _selected == null ||
                        _reasonController.text.trim().isEmpty)
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2530),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        L.t(en, 'সংরক্ষণ করুন', 'Save'),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RiskChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : const Color(0xFFF5F1F3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected
                    ? color
                    : Colors.transparent,
                width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: selected ? color : const Color(0xFF655A62),
                fontWeight:
                    selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Prescribe sheet ───────────────────────────────────────────────────────────

class _PrescribeSheet extends StatefulWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _PrescribeSheet({required this.patient, required this.en});

  @override
  State<_PrescribeSheet> createState() => _PrescribeSheetState();
}

class _PrescribeSheetState extends State<_PrescribeSheet> {
  final _controller = TextEditingController();
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSaving = true);
    await DemoRepository.instance.prescribeCareItem(
      patientId: widget.patient.id,
      text: text,
    );
    if (mounted) setState(() { _isSaving = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'প্রেসক্রিপশন যোগ করুন', 'Add Prescription'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            L.t(
              en,
              '${widget.patient.name}-এর যত্ন পরিকল্পনায় যোগ হবে।',
              'Will appear in ${widget.patient.name}\'s care plan.',
            ),
            style: GoogleFonts.nunito(
                color: const Color(0xFF675A63), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_saved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF197A5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.t(en, 'প্রেসক্রিপশন যোগ হয়েছে।',
                          'Prescription added.'),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF197A5B),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: L.t(
                  en,
                  'যেমন: প্রতিদিন সকালে ফেরাস সালফেট ২০০মিগ্রা।',
                  'e.g. Take ferrous sulfate 200mg every morning.',
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        L.t(en, 'যোগ করুন', 'Add to Care Plan'),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Refer sheet ───────────────────────────────────────────────────────────────

class _ReferSheet extends StatefulWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _ReferSheet({required this.patient, required this.en});

  @override
  State<_ReferSheet> createState() => _ReferSheetState();
}

class _ReferSheetState extends State<_ReferSheet> {
  DemoSpecialist? _selected;
  final _reasonEnController = TextEditingController();
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _reasonEnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final reason = _reasonEnController.text.trim();
    if (reason.isEmpty) return;
    setState(() => _isSaving = true);
    await DemoRepository.instance.referToSpecialist(
      patientId: widget.patient.id,
      specialist: _selected!,
      reasonBn: reason,
      reasonEn: reason,
    );
    if (mounted) setState(() { _isSaving = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    final specialists = DemoRepository.instance.specialists;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'বিশেষজ্ঞের কাছে রেফার', 'Refer to Specialist'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          if (_saved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF197A5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.t(en, 'রেফার পাঠানো হয়েছে।',
                          'Referral sent to patient.'),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF197A5B),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...specialists.map((s) => RadioListTile<DemoSpecialist>(
                  value: s,
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v),
                  title: Text(s.displayName(en),
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800)),
                  subtitle: Text(s.displaySpecialty(en),
                      style: GoogleFonts.nunito(fontSize: 12)),
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonEnController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: L.t(en, 'রেফারের কারণ লিখুন…',
                    'Reason for referral…'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isSaving ||
                        _selected == null ||
                        _reasonEnController.text.trim().isEmpty)
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5D53B7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        L.t(en, 'রেফার পাঠান', 'Send Referral'),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Annotation sheet ──────────────────────────────────────────────────────────

class _AnnotationSheet extends StatefulWidget {
  final String patientId;
  final DateTime loggedAt;
  final String? existing;
  final bool en;

  const _AnnotationSheet({
    required this.patientId,
    required this.loggedAt,
    required this.existing,
    required this.en,
  });

  @override
  State<_AnnotationSheet> createState() => _AnnotationSheetState();
}

class _AnnotationSheetState extends State<_AnnotationSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.existing ?? '');
  bool _isSaving = false;
  bool _saved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSaving = true);
    await DemoRepository.instance.annotateReading(
      patientId: widget.patientId,
      loggedAt: widget.loggedAt,
      annotation: text,
    );
    if (mounted) setState(() { _isSaving = false; _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'রিডিং-এ মন্তব্য', 'Annotate Reading'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('d MMM yyyy, h:mm a').format(widget.loggedAt),
            style: GoogleFonts.nunito(
                color: const Color(0xFF675A63), fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_saved)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF197A5B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.t(en, 'মন্তব্য সংরক্ষিত হয়েছে।',
                          'Annotation saved.'),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF197A5B),
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: L.t(
                  en,
                  'যেমন: এই রিডিংয়ে অ্যান্টিহাইপারটেনসিভ শুরু করা হয়েছে।',
                  'e.g. Started antihypertensives at this reading.',
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5D53B7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        L.t(en, 'সংরক্ষণ করুন', 'Save'),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _ReadingRow extends StatelessWidget {
  final VitalsLog log;
  final bool isLast;
  final bool en;
  final String? annotation;
  final VoidCallback? onAnnotate;

  const _ReadingRow({
    required this.log,
    required this.isLast,
    required this.en,
    this.annotation,
    this.onAnnotate,
  });

  @override
  Widget build(BuildContext context) {
    final elevated = log.systolicBp >= 140 || log.diastolicBp >= 90;
    final color =
        elevated ? const Color(0xFFD1423B) : const Color(0xFF197A5B);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    elevated
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 16,
                    color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.systolicBp}/${log.diastolicBp} mmHg',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800, color: color),
                    ),
                    Text(
                      L.t(
                        en,
                        'কিক ${log.kickCount} • ওজন ${log.weightKg.toStringAsFixed(1)} কেজি',
                        'Kick ${log.kickCount} • Weight ${log.weightKg.toStringAsFixed(1)} kg',
                      ),
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF786B72)),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('d MMM\nh:mm a').format(log.loggedAt),
                textAlign: TextAlign.right,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: const Color(0xFF9C8D96)),
              ),
              if (onAnnotate != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onAnnotate,
                  child: Icon(
                    annotation != null
                        ? Icons.sticky_note_2_rounded
                        : Icons.sticky_note_2_outlined,
                    size: 18,
                    color: annotation != null
                        ? const Color(0xFF5D53B7)
                        : const Color(0xFFB0A0A8),
                  ),
                ),
              ],
            ],
          ),
          if (annotation != null) ...[
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.only(left: 44),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF5D53B7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                annotation!,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF5D53B7),
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
