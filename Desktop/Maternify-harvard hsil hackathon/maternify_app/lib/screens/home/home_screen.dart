import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../demo/demo_repository.dart';
import '../../utils/l10n.dart';
import '../dietary/dietary_screen.dart';
import '../journal/journal_screen.dart';
import '../sos/sos_screen.dart';
import '../doctor/patient_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../specialist/specialist_list_screen.dart';
import '../timeline/timeline_screen.dart';
import '../triage/triage_screen.dart';
import '../vitals/vitals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final DemoRepository _repository = DemoRepository.instance;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (authState.user.role == DemoRole.doctor) {
      return _DoctorPreviewScreen(session: authState.user);
    }

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final en = _repository.isEnglish;
        final patientId = authState.user.patientId!;

        final body = switch (_selectedIndex) {
          0 => _MotherDashboard(
              session: authState.user,
              onNavigate: (index) => setState(() => _selectedIndex = index),
            ),
          1 => VitalsScreen(patientId: patientId),
          2 => TriageScreen(patientId: patientId),
          3 => DietaryScreen(
              patientId: patientId,
              weeksGestation: _repository.motherPatient.weeksGestation,
            ),
          4 => JournalScreen(patientId: patientId),
          5 => SosScreen(patient: _repository.motherPatient),
          _ => const SizedBox.shrink(),
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Maternify'),
            actions: [
              IconButton(
                tooltip: en ? 'বাংলা' : 'English',
                onPressed: _repository.toggleLanguage,
                icon: Icon(en
                    ? Icons.translate_rounded
                    : Icons.language_rounded),
              ),
              IconButton(
                tooltip: L.t(en, 'সেটিংস', 'Settings'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(session: authState.user),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: body,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => setState(() => _selectedIndex = 5),
            backgroundColor: const Color(0xFFE24B4A),
            icon: const Icon(Icons.sos_rounded),
            label: const Text('SOS'),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: [
              NavigationDestination(
                icon: _repository.unreadClinicAlertCount > 0
                    ? Badge(
                        label: Text(
                            '${_repository.unreadClinicAlertCount}'),
                        child: const Icon(Icons.home_outlined),
                      )
                    : const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: L.t(en, 'হোম', 'Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.monitor_heart_outlined),
                selectedIcon: const Icon(Icons.monitor_heart_rounded),
                label: L.t(en, 'রিডিং', 'Vitals'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: const Icon(Icons.chat_bubble_rounded),
                label: L.t(en, 'বিশ্লেষণ', 'Triage'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu_rounded),
                label: L.t(en, 'পুষ্টি', 'Diet'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.book_outlined),
                selectedIcon: const Icon(Icons.book_rounded),
                label: L.t(en, 'ডায়েরি', 'Journal'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.warning_amber_outlined),
                selectedIcon: const Icon(Icons.warning_rounded),
                label: L.t(en, 'জরুরি', 'Urgent'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MotherDashboard extends StatelessWidget {
  final DemoSession session;
  final ValueChanged<int> onNavigate;

  const _MotherDashboard({
    required this.session,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        final patient = repository.motherPatient;
        final latest = repository.latestVitals;
        final dueDate = DateTime.now().add(
          Duration(days: (40 - patient.weeksGestation) * 7),
        );

        final nudge = repository.getNudge(patient.id);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (nudge != null) ...[
              _VitalsNudgeBanner(
                  nudge: nudge, en: en, repository: repository),
              const SizedBox(height: 14),
            ],
            _RiskBanner(repository: repository),
            const SizedBox(height: 14),
            // Greeting card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B2E50), Color(0xFFB44C71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L.t(en, 'স্বাগতম, ${session.name.split(' ').first}',
                        'Welcome, ${session.name.split(' ').first}'),
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L.t(en, '${patient.weeksGestation} সপ্তাহ গর্ভকাল',
                        '${patient.weeksGestation} weeks pregnant'),
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroStat(
                          label: L.t(en, 'সর্বশেষ BP', 'Latest BP'),
                          value:
                              '${latest.systolicBp}/${latest.diastolicBp}'),
                      const SizedBox(width: 10),
                      _HeroStat(
                          label: L.t(en, 'কিক কাউন্ট', 'Kick Count'),
                          value: '${latest.kickCount}/2h'),
                      const SizedBox(width: 10),
                      _HeroStat(
                          label: L.t(en, 'প্রসবের তারিখ', 'Due Date'),
                          value: DateFormat('d MMM').format(dueDate)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              L.t(en, 'দ্রুত কাজ', 'Quick Actions'),
              style: GoogleFonts.nunito(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _ActionTile(
                  title: L.t(en, 'আজকের রিডিং লগ করুন',
                      'Log Today\'s Reading'),
                  subtitle: L.t(en, 'চার্ট আপডেট করুন', 'Update your chart'),
                  icon: Icons.monitor_heart_rounded,
                  color: const Color(0xFF983755),
                  onTap: () => onNavigate(1),
                ),
                _ActionTile(
                  title: L.t(en, 'লক্ষণ বিশ্লেষণ করুন', 'Analyze Symptoms'),
                  subtitle:
                      L.t(en, 'বাংলায় লক্ষণ জানান', 'Describe how you feel'),
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF0F6E56),
                  onTap: () => onNavigate(2),
                ),
                _ActionTile(
                  title: L.t(en, 'জরুরি SOS', 'Emergency SOS'),
                  subtitle: L.t(en, 'জরুরি সাহায্যের জন্য চাপুন',
                      'Tap for urgent help'),
                  icon: Icons.sos_rounded,
                  color: const Color(0xFFE24B4A),
                  onTap: () => onNavigate(5),
                ),
                _ActionTile(
                  title: L.t(en, 'ক্লিনিক আপডেট দেখুন', 'Clinic Updates'),
                  subtitle: L.t(en, 'আপনার চিকিৎসকের মতামত',
                      'Your care team\'s notes'),
                  icon: Icons.local_hospital_outlined,
                  color: const Color(0xFF5D53B7),
                  badgeCount: repository.unreadClinicAlertCount,
                  onTap: () {
                    repository.markClinicAlertsRead();
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) =>
                          _ProviderPeekSheet(repository: repository),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Care Network tile — full width
            _CareNetworkTile(en: en),
            const SizedBox(height: 10),
            // Timeline tile — full width
            _TimelineTile(en: en, patientId: patient.id),
            const SizedBox(height: 16),

            // My appointments
            if (repository.appointments.isNotEmpty) ...[
              Text(
                L.t(en, 'আমার অ্যাপয়েন্টমেন্ট', 'My Appointments'),
                style: GoogleFonts.nunito(
                    fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...repository.appointments.map((apt) =>
                  _PatientAppointmentCard(appointment: apt, en: en)),
              const SizedBox(height: 16),
            ],

            // AI summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t(en, 'AI স্বাস্থ্য সারসংক্ষেপ', 'AI Health Summary'),
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repository.aiSummaryBangla,
                      style: GoogleFonts.nunito(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MetricPill(
                          label: L.t(en, 'গ্লুকোজ', 'Glucose'),
                          value:
                              '${latest.bloodGlucose.toStringAsFixed(1)} mmol/L',
                        ),
                        const SizedBox(width: 8),
                        _MetricPill(
                          label: L.t(en, 'ওজন', 'Weight'),
                          value: '${latest.weightKg.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Care plan
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t(en, 'আজকের যত্ন পরিকল্পনা', 'Today\'s Care Plan'),
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _CareRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: L.t(en, 'দুপুরের পরে আবার BP মাপুন',
                          'Measure BP again after noon'),
                      subtitle: L.t(en, 'বিশ্রামের পরে রক্তচাপ লগ করুন।',
                          'Log your blood pressure after resting.'),
                      checked: repository.isCarePlanChecked('care-bp'),
                      onToggle: () =>
                          repository.toggleCarePlanItem('care-bp'),
                    ),
                    _CareRow(
                      icon: Icons.medical_information_outlined,
                      title: L.t(
                          en,
                          'মাথা ঘোরা বা চোখে ঝাপসা দেখলে সতর্ক থাকুন',
                          'Watch for dizziness or blurred vision'),
                      subtitle: L.t(en, 'লক্ষণ বাড়লে দ্রুত চিকিৎসা নিন।',
                          'Seek care promptly if symptoms worsen.'),
                      checked: repository.isCarePlanChecked('care-dizziness'),
                      onToggle: () => repository
                          .toggleCarePlanItem('care-dizziness'),
                    ),
                    _CareRow(
                      icon: Icons.notifications_active_outlined,
                      title: repository.sosTriggered
                          ? L.t(en, 'SOS পাঠানো হয়েছে', 'SOS Dispatched')
                          : L.t(en, 'SOS প্রস্তুত রাখুন', 'Keep SOS ready'),
                      subtitle: repository.sosTriggered
                          ? L.t(
                              en,
                              'আপনার ক্লিনিক টিম ইতোমধ্যে আপনার জরুরি অনুরোধ পেয়েছে।',
                              'Your clinic team has already received your emergency request.')
                          : L.t(
                              en,
                              'একবার চাপলেই ক্লিনিক টিম সাথে সাথে জানতে পারবে।',
                              'One tap alerts your clinic team immediately.'),
                      isLast: repository
                          .getCareItems(patient.id)
                          .isEmpty,
                    ),
                    ...repository
                        .getCareItems(patient.id)
                        .asMap()
                        .entries
                        .map((e) => _CareRow(
                              icon: Icons.medical_services_outlined,
                              title: L.t(en, 'চিকিৎসকের পরামর্শ',
                                  "Doctor's Prescription"),
                              subtitle: e.value.text,
                              isLast: e.key ==
                                  repository
                                          .getCareItems(patient.id)
                                          .length -
                                      1,
                            )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              L.t(en, 'সাম্প্রতিক সতর্কতা', 'Recent Alerts'),
              style: GoogleFonts.nunito(
                  fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...repository.alerts
                .where((a) => !a.isReviewed)
                .take(4)
                .map((alert) => _AlertCard(
                      alert: alert,
                      en: en,
                      onAcknowledged: () =>
                          repository.acknowledgeAlert(alert.id),
                      onTap: switch (alert.alertType) {
                        DemoAlertType.referral => () =>
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const SpecialistListScreen(),
                              ),
                            ),
                        DemoAlertType.vitals ||
                        DemoAlertType.triage =>
                          () => onNavigate(1),
                        _ => null,
                      },
                    )),
            if (repository.alerts.where((a) => !a.isReviewed).isEmpty)
              _EmptyState(
                icon: Icons.notifications_none_rounded,
                message: L.t(en, 'কোনো নতুন সতর্কতা নেই।',
                    'No new alerts.'),
              ),
          ],
        );
      },
    );
  }
}

class _DoctorPreviewScreen extends StatelessWidget {
  final DemoSession session;

  const _DoctorPreviewScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    final repository = DemoRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final en = repository.isEnglish;
        return Scaffold(
          appBar: AppBar(
            title: Text(L.t(en, 'চিকিৎসক ভিউ', 'Doctor View')),
            actions: [
              IconButton(
                tooltip: L.t(en, 'সকলকে বার্তা', 'Broadcast to All'),
                onPressed: () => _showBroadcastSheet(context, en, repository),
                icon: const Icon(Icons.campaign_rounded),
              ),
              IconButton(
                tooltip: en ? 'বাংলা' : 'English',
                onPressed: repository.toggleLanguage,
                icon: const Icon(Icons.translate_rounded),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(session: session),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(AuthSignOutRequested()),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2530),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${session.name.split(' ').last}',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      L.t(
                        en,
                        'সাম্প্রতিক সতর্কতা দেখুন এবং জরুরি রোগীদের অগ্রাধিকার দিন।',
                        'Review recent alerts and prioritize urgent patients.',
                      ),
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Stats strip
              _DoctorStatsStrip(en: en, repository: repository),
              const SizedBox(height: 14),

              // Quick actions
              _DoctorQuickActions(en: en),
              const SizedBox(height: 16),

              // Incoming appointments
              if (repository.appointments.isNotEmpty) ...[
                Text(
                  L.t(en, 'নতুন অ্যাপয়েন্টমেন্ট', 'Incoming Appointments'),
                  style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...repository.appointments
                    .take(3)
                    .map((apt) => _AppointmentCard(
                          appointment: apt,
                          repository: repository,
                          en: en,
                        )),
                const SizedBox(height: 16),
              ],

              // Today's schedule
              if (repository.appointments.isNotEmpty) ...[
                Text(
                  L.t(en, 'আজকের সময়সূচি', "Today's Schedule"),
                  style: GoogleFonts.nunito(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: repository.appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final apt = repository.appointments[i];
                      return _ScheduleChip(appointment: apt, en: en);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                L.t(en, 'সাম্প্রতিক সতর্কতা', 'Recent Alerts'),
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...repository.alerts
                  .where((a) => !a.isReviewed)
                  .take(4)
                  .map((alert) => _AlertCard(
                        alert: alert,
                        en: en,
                        onReviewed: () =>
                            repository.markAlertReviewed(alert.id),
                      )),
              const SizedBox(height: 16),
              Text(
                L.t(en, 'রোগীর অগ্রাধিকার তালিকা', 'Patient Priority List'),
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...repository.providerPatients
                  .map((patient) => _ProviderPatientCard(
                        patient: patient,
                        en: en,
                      )),
            ],
          ),
        );
      },
    );
  }
}

// ── Care Network tile ─────────────────────────────────────────────────────────

class _CareNetworkTile extends StatelessWidget {
  final bool en;

  const _CareNetworkTile({required this.en});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => const SpecialistListScreen()),
      ),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF5D53B7).withValues(alpha: 0.12),
              const Color(0xFF8B2E50).withValues(alpha: 0.08),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF5D53B7).withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D53B7).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: Color(0xFF5D53B7)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t(en, 'বিশেষজ্ঞ খুঁজুন', 'Find a Specialist'),
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF322730),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      L.t(
                        en,
                        'OB/GYN, উচ্চ-ঝুঁকি বিশেষজ্ঞ ও পুষ্টিবিদ',
                        'OB/GYN, high-risk specialists & nutritionists',
                      ),
                      style: GoogleFonts.nunito(
                          fontSize: 12.5, color: const Color(0xFF675A63)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF5D53B7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Appointment card (doctor view) ────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final DemoAppointment appointment;
  final DemoRepository repository;
  final bool en;

  const _AppointmentCard({
    required this.appointment,
    required this.repository,
    required this.en,
  });

  @override
  Widget build(BuildContext context) {
    final latest = repository.latestVitals;
    final riskColor = switch (repository.currentRiskLevel) {
      DemoRiskLevel.green => const Color(0xFF197A5B),
      DemoRiskLevel.yellow => const Color(0xFFB17616),
      DemoRiskLevel.red => const Color(0xFFD1423B),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF5D53B7).withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D53B7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      L.t(en, 'নতুন অ্যাপয়েন্টমেন্ট', 'New Appointment'),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFF5D53B7),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (appointment.vitalsShared)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF197A5B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.share_rounded,
                              size: 12, color: Color(0xFF197A5B)),
                          const SizedBox(width: 4),
                          Text(
                            L.t(en, 'ভাইটালস শেয়ার', 'Vitals Shared'),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: const Color(0xFF197A5B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                repository.motherPatient.name,
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                L.t(
                  en,
                  '${repository.motherPatient.weeksGestation} সপ্তাহ • BP ${latest.systolicBp}/${latest.diastolicBp} • কিক কাউন্ট ${latest.kickCount}',
                  '${repository.motherPatient.weeksGestation} weeks pregnant • BP ${latest.systolicBp}/${latest.diastolicBp} • Kick count ${latest.kickCount}',
                ),
                style: GoogleFonts.nunito(color: const Color(0xFF655A62)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${L.t(en, 'ঝুঁকি', 'Risk')}: ${repository.riskLabel}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: riskColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${appointment.isOnline ? L.t(en, 'অনলাইন', 'Online') : L.t(en, 'সশরীরে', 'In-person')} • ${appointment.displaySlot(en)}',
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF786B72), fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                L.t(
                  en,
                  'উচ্চ-ঝুঁকির লক্ষণের পরে অ্যাপয়েন্টমেন্ট নেওয়া হয়েছে। রোগীর সর্বশেষ রিডিং সংযুক্ত।',
                  'Booked after a high-risk symptom event. Patient\'s latest readings are attached.',
                ),
                style: GoogleFonts.nunito(
                    height: 1.4,
                    fontSize: 13,
                    color: const Color(0xFF655A62)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Risk banner ───────────────────────────────────────────────────────────────

class _RiskBanner extends StatelessWidget {
  final DemoRepository repository;

  const _RiskBanner({required this.repository});

  @override
  Widget build(BuildContext context) {
    final color = switch (repository.currentRiskLevel) {
      DemoRiskLevel.green => const Color(0xFF197A5B),
      DemoRiskLevel.yellow => const Color(0xFFB17616),
      DemoRiskLevel.red => const Color(0xFFD1423B),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            repository.currentRiskLevel == DemoRiskLevel.red
                ? Icons.warning_rounded
                : Icons.analytics_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${repository.riskLabelBangla} • ${repository.riskLabel}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  repository.riskSummaryBangla,
                  style: GoogleFonts.nunito(fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF322730),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  color: const Color(0xFF675A63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (badgeCount > 0) {
      return Badge(
        label: Text('$badgeCount'),
        child: tile,
      );
    }
    return tile;
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F1F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 11, color: const Color(0xFF675A63))),
            const SizedBox(height: 3),
            Text(value,
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CareRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;
  final bool checked;
  final VoidCallback? onToggle;

  const _CareRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
    this.checked = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = checked
        ? const Color(0xFF197A5B)
        : const Color(0xFF993556);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                checked ? Icons.check_circle_rounded : icon,
                size: 18,
                color: effectiveColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      decoration: checked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: checked
                          ? const Color(0xFF197A5B)
                          : const Color(0xFF322730),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF6C6068), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DemoAlert alert;
  final bool en;
  final VoidCallback? onReviewed;
  final VoidCallback? onAcknowledged;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.alert,
    required this.en,
    this.onReviewed,
    this.onAcknowledged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.riskLevel) {
      DemoRiskLevel.green => const Color(0xFF197A5B),
      DemoRiskLevel.yellow => const Color(0xFFB17616),
      DemoRiskLevel.red => const Color(0xFFD1423B),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(
                alert.urgent ? Icons.notifications_active : Icons.info_outline),
          ),
          title: Text(alert.title,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child:
                Text(alert.message, style: GoogleFonts.nunito(height: 1.35)),
          ),
          trailing: onReviewed != null
              ? IconButton(
                  tooltip: L.t(en, 'পর্যালোচিত', 'Mark reviewed'),
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF197A5B)),
                  onPressed: onReviewed,
                )
              : onAcknowledged != null
                  ? TextButton(
                      onPressed: onAcknowledged,
                      child: Text(
                        L.t(en, 'বুঝলাম', 'Got it'),
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF993556)),
                      ),
                    )
                  : Text(
                      DateFormat('h:mm a').format(alert.createdAt),
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: const Color(0xFF786B72)),
                    ),
        ),
      ),
    );
  }
}

class _ProviderPeekSheet extends StatelessWidget {
  final DemoRepository repository;

  const _ProviderPeekSheet({required this.repository});

  @override
  Widget build(BuildContext context) {
    final en = repository.isEnglish;
    final nusrat = repository.providerPatients.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L.t(en, 'ক্লিনিক টিমের আপডেট', 'Clinic Team Update'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            L.t(
              en,
              'আপনার চিকিৎসকের পাঠানো সর্বশেষ রোগীর অবস্থা।',
              'Latest patient status from your care team.',
            ),
            style: GoogleFonts.nunito(color: const Color(0xFF675A63)),
          ),
          const SizedBox(height: 14),
          _ProviderPatientCard(patient: nusrat, en: en),
        ],
      ),
    );
  }
}

// ── Doctor stats strip ────────────────────────────────────────────────────────

class _DoctorStatsStrip extends StatelessWidget {
  final bool en;
  final DemoRepository repository;

  const _DoctorStatsStrip({required this.en, required this.repository});

  @override
  Widget build(BuildContext context) {
    final patients = repository.providerPatients;
    final red = patients.where((p) => p.riskLevel == DemoRiskLevel.red).length;
    final yellow =
        patients.where((p) => p.riskLevel == DemoRiskLevel.yellow).length;
    final green =
        patients.where((p) => p.riskLevel == DemoRiskLevel.green).length;

    return Row(
      children: [
        _StatChip(
          value: '${patients.length}',
          label: L.t(en, 'মোট', 'Total'),
          color: const Color(0xFF5D53B7),
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: '$red',
          label: L.t(en, 'জরুরি', 'Urgent'),
          color: const Color(0xFFD1423B),
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: '$yellow',
          label: L.t(en, 'নজরে', 'Watch'),
          color: const Color(0xFFB17616),
        ),
        const SizedBox(width: 8),
        _StatChip(
          value: '$green',
          label: L.t(en, 'স্থিতিশীল', 'Stable'),
          color: const Color(0xFF197A5B),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Doctor quick actions ──────────────────────────────────────────────────────

class _DoctorQuickActions extends StatelessWidget {
  final bool en;

  const _DoctorQuickActions({required this.en});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionTile(
          icon: Icons.queue_rounded,
          label: L.t(en, "আজকের কিউ", "Today's Queue"),
          color: const Color(0xFF1F2530),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                L.t(en, '৩ জন রোগী আজকের তালিকায়।',
                    '3 patients in today\'s queue.'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _QuickActionTile(
          icon: Icons.notifications_active_rounded,
          label: L.t(en, "অপঠিত সতর্কতা", "Unread Alerts"),
          color: const Color(0xFFD1423B),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                L.t(en, '২টি অপঠিত সতর্কতা আছে।',
                    '2 unread alerts waiting.'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _QuickActionTile(
          icon: Icons.summarize_rounded,
          label: L.t(en, "ডে সামারি", "Day Summary"),
          color: const Color(0xFF0F6E56),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                L.t(en, 'কাল কোনো ফলো-আপ নেই।',
                    'No follow-ups scheduled tomorrow.'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Provider patient card ─────────────────────────────────────────────────────

class _ProviderPatientCard extends StatelessWidget {
  final DemoProviderPatient patient;
  final bool en;

  const _ProviderPatientCard({required this.patient, required this.en});

  @override
  Widget build(BuildContext context) {
    final color = switch (patient.riskLevel) {
      DemoRiskLevel.green => const Color(0xFF197A5B),
      DemoRiskLevel.yellow => const Color(0xFFB17616),
      DemoRiskLevel.red => const Color(0xFFD1423B),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DoctorPatientDetailScreen(patient: patient),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        patient.name,
                        style: GoogleFonts.nunito(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        en
                            ? switch (patient.riskLevel) {
                                DemoRiskLevel.green => 'Stable',
                                DemoRiskLevel.yellow => 'Watch',
                                DemoRiskLevel.red => 'Urgent',
                              }
                            : switch (patient.riskLevel) {
                                DemoRiskLevel.green => 'সবুজ',
                                DemoRiskLevel.yellow => 'হলুদ',
                                DemoRiskLevel.red => 'লাল',
                              },
                        style: GoogleFonts.nunito(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        color: const Color(0xFFB0A0A8), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.nunito(color: const Color(0xFF655A62)),
                    children: [
                      TextSpan(
                        text: L.t(
                          en,
                          '${patient.weeksGestation} সপ্তাহ • BP ${patient.latestBp} • ',
                          '${patient.weeksGestation} weeks • BP ${patient.latestBp} • ',
                        ),
                      ),
                      TextSpan(
                        text: L.t(
                          en,
                          '${patient.daysSinceLog} দিন আগে লগ',
                          'logged ${patient.daysSinceLog}d ago',
                        ),
                        style: GoogleFonts.nunito(
                          color: patient.daysSinceLog >= 3
                              ? const Color(0xFFD1423B)
                              : patient.daysSinceLog >= 2
                                  ? const Color(0xFFB17616)
                                  : const Color(0xFF197A5B),
                          fontWeight: patient.daysSinceLog >= 2
                              ? FontWeight.w800
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(patient.summary,
                    style: GoogleFonts.nunito(height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Broadcast sheet ───────────────────────────────────────────────────────────

void _showBroadcastSheet(
    BuildContext context, bool en, DemoRepository repository) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BroadcastSheet(en: en, repository: repository),
  );
}

class _BroadcastSheet extends StatefulWidget {
  final bool en;
  final DemoRepository repository;

  const _BroadcastSheet({required this.en, required this.repository});

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    await widget.repository.broadcastToAllPatients(text);
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
            L.t(en, 'সকল রোগীকে বার্তা পাঠান', 'Broadcast to All Patients'),
            style: GoogleFonts.nunito(
                fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            L.t(
              en,
              'এই বার্তা সকল রোগীর "সাম্প্রতিক সতর্কতা"-তে দেখাবে।',
              'This message will appear in all patients\' Recent Alerts.',
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
                      L.t(en, 'বার্তা পাঠানো হয়েছে।',
                          'Broadcast sent successfully.'),
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
                  'যেমন: আগামীকাল ক্লিনিক বন্ধ থাকবে।',
                  'e.g. Clinic will be closed tomorrow.',
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.campaign_rounded),
                label: Text(
                  L.t(en, 'পাঠান', 'Send Broadcast'),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2530),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Schedule chip (horizontal scroll in doctor view) ─────────────────────────

class _ScheduleChip extends StatelessWidget {
  final DemoAppointment appointment;
  final bool en;

  const _ScheduleChip({required this.appointment, required this.en});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF5D53B7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF5D53B7).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D53B7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.isOnline
                      ? L.t(en, 'অনলাইন', 'Online')
                      : L.t(en, 'সশরীরে', 'In-person'),
                  style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: const Color(0xFF5D53B7),
                      fontWeight: FontWeight.w800),
                ),
              ),
              if (appointment.vitalsShared) ...[
                const SizedBox(width: 6),
                const Icon(Icons.share_rounded,
                    size: 12, color: Color(0xFF197A5B)),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.displayName(en),
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                appointment.displaySlot(en),
                style: GoogleFonts.nunito(
                    fontSize: 11, color: const Color(0xFF786B72)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Vitals nudge banner (mother view) ────────────────────────────────────────

class _VitalsNudgeBanner extends StatelessWidget {
  final DemoVitalsNudge nudge;
  final bool en;
  final DemoRepository repository;

  const _VitalsNudgeBanner(
      {required this.nudge,
      required this.en,
      required this.repository});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5D53B7).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF5D53B7).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_heart_rounded,
              color: Color(0xFF5D53B7), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nudge.displayMessage(en),
              style: GoogleFonts.nunito(
                  color: const Color(0xFF5D53B7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF5D53B7)),
            onPressed: () => repository.dismissNudge(nudge.patientId),
          ),
        ],
      ),
    );
  }
}

// ── Timeline tile (patient home) ──────────────────────────────────────────────

class _TimelineTile extends StatelessWidget {
  final bool en;
  final String patientId;

  const _TimelineTile({required this.en, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => TimelineScreen(patientId: patientId)),
      ),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2530).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF1F2530).withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2530).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.timeline_rounded,
                    color: Color(0xFF1F2530), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L.t(en, 'কার্যকলাপের ইতিহাস', 'Activity Timeline'),
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF322730),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      L.t(en, 'সমস্ত রিডিং, লক্ষণ ও বার্তা',
                          'All readings, symptoms & clinic messages'),
                      style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          color: const Color(0xFF675A63)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFB0A0A8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient appointment card ──────────────────────────────────────────────────

class _PatientAppointmentCard extends StatelessWidget {
  final DemoAppointment appointment;
  final bool en;

  const _PatientAppointmentCard(
      {required this.appointment, required this.en});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5D53B7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                appointment.isOnline
                    ? Icons.videocam_rounded
                    : Icons.local_hospital_outlined,
                color: const Color(0xFF5D53B7),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.displayName(en),
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    appointment.displaySpecialty(en),
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF786B72)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF197A5B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    L.t(en, 'নিশ্চিত', 'Confirmed'),
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: const Color(0xFF197A5B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.displaySlot(en),
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: const Color(0xFF9C8D96)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon,
                size: 40, color: Colors.grey.withValues(alpha: 0.35)),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.nunito(
                  color: const Color(0xFF9C8D96), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
