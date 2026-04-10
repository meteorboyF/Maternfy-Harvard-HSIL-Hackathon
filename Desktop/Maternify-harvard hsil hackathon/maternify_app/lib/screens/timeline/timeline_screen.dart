import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';

class TimelineScreen extends StatelessWidget {
  final String patientId;

  const TimelineScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        final entries = repository.getPatientTimeline(patientId);
        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'কার্যকলাপের ইতিহাস', 'Activity Timeline')),
            actions: [
              IconButton(
                tooltip: en ? 'বাংলা' : 'English',
                onPressed: repository.toggleLanguage,
                icon: const Icon(Icons.translate_rounded),
              ),
            ],
          ),
          body: entries.isEmpty
              ? _EmptyTimeline(en: en)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isLast = index == entries.length - 1;
                    return _TimelineRow(
                        entry: entry, isLast: isLast, en: en);
                  },
                ),
        );
      },
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final bool en;
  const _EmptyTimeline({required this.en});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline_rounded,
              size: 64, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            L.t(en, 'এখনো কোনো কার্যকলাপ নেই।', 'No activity yet.'),
            style: GoogleFonts.nunito(
                fontSize: 16, color: const Color(0xFF786B72)),
          ),
          const SizedBox(height: 8),
          Text(
            L.t(en, 'ভাইটালস লগ করলে এখানে দেখাবে।',
                'Log your first vitals to see them here.'),
            style: GoogleFonts.nunito(
                fontSize: 13, color: const Color(0xFF9C8D96)),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final DemoTimelineEntry entry;
  final bool isLast;
  final bool en;

  const _TimelineRow(
      {required this.entry, required this.isLast, required this.en});

  @override
  Widget build(BuildContext context) {
    final color = switch (entry.severity) {
      DemoRiskLevel.red => const Color(0xFFD1423B),
      DemoRiskLevel.yellow => const Color(0xFFB17616),
      DemoRiskLevel.green => const Color(0xFF197A5B),
    };

    final icon = switch (entry.type) {
      'vitals' => Icons.monitor_heart_rounded,
      'triage' => Icons.chat_bubble_rounded,
      'sos' => Icons.sos_rounded,
      'appointment' => Icons.calendar_month_rounded,
      _ => Icons.notifications_rounded,
    };

    final typeLabel = switch (entry.type) {
      'vitals' => L.t(en, 'রিডিং', 'Reading'),
      'triage' => L.t(en, 'লক্ষণ', 'Symptom'),
      'sos' => 'SOS',
      'appointment' => L.t(en, 'অ্যাপয়েন্টমেন্ট', 'Appointment'),
      _ => L.t(en, 'বার্তা', 'Alert'),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE8DEE3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(entry.timestamp),
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: const Color(0xFF9C8D96)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.title(en),
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: const Color(0xFF322730)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.subtitle(en),
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF675A63),
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}
