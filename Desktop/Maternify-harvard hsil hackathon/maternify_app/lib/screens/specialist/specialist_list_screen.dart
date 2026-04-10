import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';
import 'specialist_profile_screen.dart';

class SpecialistListScreen extends StatefulWidget {
  const SpecialistListScreen({super.key});

  @override
  State<SpecialistListScreen> createState() => _SpecialistListScreenState();
}

class _SpecialistListScreenState extends State<SpecialistListScreen> {
  String _activeFilter = 'all';
  bool _onlineOnly = false;

  static const _filters = {
    'all': ('সকল', 'All'),
    'obgyn': ('প্রসূতি ও স্ত্রীরোগ', 'OB/GYN'),
    'high_risk': ('উচ্চ-ঝুঁকি', 'High-Risk'),
    'nutrition': ('পুষ্টি', 'Nutrition'),
  };

  List<DemoSpecialist> _filtered(List<DemoSpecialist> all) {
    var list = all.where((s) {
      if (_onlineOnly && !s.hasOnlineConsultation) return false;
      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'obgyn') return s.id == 'specialist-amina';
      if (_activeFilter == 'high_risk') return s.id == 'specialist-rafiqul';
      if (_activeFilter == 'nutrition') return s.id == 'specialist-nasrin';
      return true;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        final specialists = _filtered(repository.specialists);

        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'বিশেষজ্ঞ খুঁজুন', 'Find a Specialist')),
            actions: [
              IconButton(
                tooltip: en ? 'বাংলা' : 'English',
                onPressed: repository.toggleLanguage,
                icon: const Icon(Icons.translate_rounded),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    ..._filters.entries.map((entry) {
                      final label =
                          en ? entry.value.$2 : entry.value.$1;
                      final selected = _activeFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label,
                              style: GoogleFonts.nunito(
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600)),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _activeFilter = entry.key),
                          selectedColor:
                              const Color(0xFF8B2E50).withValues(alpha: 0.12),
                          checkmarkColor: const Color(0xFF8B2E50),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF8B2E50)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 4),
                    FilterChip(
                      label: Text(
                        L.t(en, 'অনলাইন', 'Online'),
                        style: GoogleFonts.nunito(
                            fontWeight: _onlineOnly
                                ? FontWeight.w800
                                : FontWeight.w600),
                      ),
                      selected: _onlineOnly,
                      avatar: const Icon(Icons.videocam_outlined, size: 16),
                      onSelected: (val) => setState(() => _onlineOnly = val),
                      selectedColor:
                          const Color(0xFF0F6E56).withValues(alpha: 0.12),
                      checkmarkColor: const Color(0xFF0F6E56),
                      side: BorderSide(
                        color: _onlineOnly
                            ? const Color(0xFF0F6E56)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Specialist count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  L.t(en, '${specialists.length} জন বিশেষজ্ঞ পাওয়া গেছে',
                      '${specialists.length} specialist(s) found'),
                  style: GoogleFonts.nunito(
                      color: const Color(0xFF675A63), fontSize: 13),
                ),
              ),

              // List
              Expanded(
                child: specialists.isEmpty
                    ? Center(
                        child: Text(
                          L.t(en, 'কোনো বিশেষজ্ঞ পাওয়া যায়নি',
                              'No specialists found'),
                          style: GoogleFonts.nunito(
                              color: const Color(0xFF675A63)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: specialists.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _SpecialistCard(
                          specialist: specialists[index],
                          isEnglish: en,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SpecialistProfileScreen(
                                  specialist: specialists[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpecialistCard extends StatelessWidget {
  final DemoSpecialist specialist;
  final bool isEnglish;
  final VoidCallback onTap;

  const _SpecialistCard({
    required this.specialist,
    required this.isEnglish,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final en = isEnglish;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B2E50), Color(0xFFB44C71)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        specialist.avatarInitials,
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
                          specialist.displayName(en),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialist.displaySpecialty(en),
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: const Color(0xFF675A63),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fee badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B2E50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '৳${specialist.fee}',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF8B2E50),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFF9C8D96)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      specialist.displayChamber(en),
                      style: GoogleFonts.nunito(
                          fontSize: 12.5, color: const Color(0xFF786B72)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    specialist.displayDistance(en),
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: const Color(0xFF786B72)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SlotChip(
                      label: specialist.nextSlot(en),
                      icon: Icons.access_time_rounded,
                    ),
                  ),
                  if (specialist.hasOnlineConsultation) ...[
                    const SizedBox(width: 8),
                    _SlotChip(
                      label: L.t(en, 'অনলাইন', 'Online'),
                      icon: Icons.videocam_rounded,
                      color: const Color(0xFF0F6E56),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2E50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    L.t(en, 'প্রোফাইল দেখুন', 'View Profile'),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
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

class _SlotChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SlotChip({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF5D53B7),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                  fontSize: 12, color: color, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
