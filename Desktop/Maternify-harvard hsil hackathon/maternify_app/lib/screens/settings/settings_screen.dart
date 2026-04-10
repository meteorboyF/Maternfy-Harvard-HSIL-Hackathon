import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';

class SettingsScreen extends StatelessWidget {
  final DemoSession session;

  const SettingsScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        final isDoctor = session.role == DemoRole.doctor;
        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'সেটিংস', 'Settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF993556)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                session.name
                                    .split(' ')
                                    .map((w) => w[0])
                                    .take(2)
                                    .join(),
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF993556),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.name,
                                  style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  session.email,
                                  style: GoogleFonts.nunito(
                                      color: const Color(0xFF675A63),
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettingRow(
                        icon: Icons.badge_outlined,
                        label: L.t(en, 'ভূমিকা', 'Role'),
                        value: isDoctor
                            ? L.t(en, 'চিকিৎসক', 'Doctor')
                            : L.t(en, 'রোগী (মা)', 'Patient (Mother)'),
                      ),
                      if (!isDoctor) ...[
                        _SettingRow(
                          icon: Icons.pregnant_woman_rounded,
                          label: L.t(en, 'গর্ভকাল', 'Gestation'),
                          value: L.t(
                            en,
                            '${repository.motherPatient.weeksGestation} সপ্তাহ',
                            '${repository.motherPatient.weeksGestation} weeks',
                          ),
                        ),
                        _SettingRow(
                          icon: Icons.bloodtype_outlined,
                          label: L.t(en, 'রক্তের গ্রুপ', 'Blood Type'),
                          value: repository.motherPatient.bloodType,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferences
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          L.t(en, 'পছন্দ', 'Preferences'),
                          style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF786B72)),
                        ),
                      ),
                      SwitchListTile(
                        value: repository.isEnglish,
                        onChanged: (_) => repository.toggleLanguage(),
                        title: Text(
                          L.t(en, 'ইংরেজি ভাষা', 'English Language'),
                          style:
                              GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          L.t(en, 'চালু থাকলে সব কিছু ইংরেজিতে দেখাবে।',
                              'When on, all text will display in English.'),
                          style: GoogleFonts.nunito(fontSize: 12),
                        ),
                        secondary: const Icon(Icons.translate_rounded),
                        activeThumbColor: const Color(0xFF993556),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App info
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            L.t(en, 'অ্যাপ সম্পর্কে', 'About'),
                            style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF786B72)),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text('Maternify',
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          L.t(en,
                              'Harvard HSIL Hackathon • Demo v1.0',
                              'Harvard HSIL Hackathon • Demo v1.0'),
                          style: GoogleFonts.nunito(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFFD1423B)),
                  label: Text(
                    L.t(en, 'সাইন আউট', 'Sign Out'),
                    style: GoogleFonts.nunito(
                        color: const Color(0xFFD1423B),
                        fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1423B)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SettingRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF993556)),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.nunito(
                color: const Color(0xFF786B72), fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
