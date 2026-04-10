import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/patient.dart';
import '../models/triage_event.dart';
import '../models/vitals_log.dart';

enum DemoRole { mother, doctor }

enum DemoRiskLevel { green, yellow, red }

class DemoSession {
  final String id;
  final String name;
  final String email;
  final DemoRole role;
  final String? patientId;

  const DemoSession({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.patientId,
  });
}

class DemoAlert {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DemoRiskLevel riskLevel;
  final bool urgent;
  final bool isReviewed;

  const DemoAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.riskLevel,
    this.urgent = false,
    this.isReviewed = false,
  });

  DemoAlert copyWithReviewed() => DemoAlert(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        riskLevel: riskLevel,
        urgent: urgent,
        isReviewed: true,
      );
}

class DemoProviderPatient {
  final String id;
  final String name;
  final int weeksGestation;
  final DemoRiskLevel riskLevel;
  final String latestBp;
  final String summary;
  final int daysSinceLog;

  const DemoProviderPatient({
    required this.id,
    required this.name,
    required this.weeksGestation,
    required this.riskLevel,
    required this.latestBp,
    required this.summary,
    required this.daysSinceLog,
  });
}

class DemoChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final TriageTier? tier;
  final bool escalationRequired;

  const DemoChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tier,
    this.escalationRequired = false,
  });
}

class DemoTriageResponse {
  final DemoChatMessage message;
  final DemoRiskLevel updatedRisk;

  const DemoTriageResponse({
    required this.message,
    required this.updatedRisk,
  });
}

class DemoSosResult {
  final String statusLine;
  final String summary;
  final List<String> steps;

  const DemoSosResult({
    required this.statusLine,
    required this.summary,
    required this.steps,
  });
}

// ── Doctor / triage-history model ────────────────────────────────────────────

class DemoTriageEvent {
  final String id;
  final String inputText;
  final String tier; // 'red' | 'yellow' | 'green'
  final String adviceBangla;
  final String adviceEnglish;
  final DateTime createdAt;
  final bool escalationRequired;

  const DemoTriageEvent({
    required this.id,
    required this.inputText,
    required this.tier,
    required this.adviceBangla,
    required this.adviceEnglish,
    required this.createdAt,
    required this.escalationRequired,
  });

  String displayAdvice(bool isEnglish) =>
      isEnglish ? adviceEnglish : adviceBangla;
}

// ── Specialist & Booking models ──────────────────────────────────────────────

class DemoSpecialist {
  final String id;
  final String nameBn;
  final String nameEn;
  final String specialtyBn;
  final String specialtyEn;
  final String hospitalBn;
  final String hospitalEn;
  final String chamberBn;
  final String chamberEn;
  final String addressBn;
  final String addressEn;
  final int fee;
  final List<String> languagesBn;
  final List<String> languagesEn;
  final List<String> availableSlotsBn;
  final List<String> availableSlotsEn;
  final bool hasOnlineConsultation;
  final String distanceBn;
  final String distanceEn;
  final String avatarInitials;
  final List<String> visitChecklistBn;
  final List<String> visitChecklistEn;

  const DemoSpecialist({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.specialtyBn,
    required this.specialtyEn,
    required this.hospitalBn,
    required this.hospitalEn,
    required this.chamberBn,
    required this.chamberEn,
    required this.addressBn,
    required this.addressEn,
    required this.fee,
    required this.languagesBn,
    required this.languagesEn,
    required this.availableSlotsBn,
    required this.availableSlotsEn,
    required this.hasOnlineConsultation,
    required this.distanceBn,
    required this.distanceEn,
    required this.avatarInitials,
    required this.visitChecklistBn,
    required this.visitChecklistEn,
  });

  String displayName(bool isEnglish) => isEnglish ? nameEn : nameBn;
  String displaySpecialty(bool isEnglish) =>
      isEnglish ? specialtyEn : specialtyBn;
  String displayHospital(bool isEnglish) =>
      isEnglish ? hospitalEn : hospitalBn;
  String displayChamber(bool isEnglish) => isEnglish ? chamberEn : chamberBn;
  String displayAddress(bool isEnglish) => isEnglish ? addressEn : addressBn;
  String displayDistance(bool isEnglish) =>
      isEnglish ? distanceEn : distanceBn;
  List<String> displayLanguages(bool isEnglish) =>
      isEnglish ? languagesEn : languagesBn;
  List<String> displaySlots(bool isEnglish) =>
      isEnglish ? availableSlotsEn : availableSlotsBn;
  List<String> displayChecklist(bool isEnglish) =>
      isEnglish ? visitChecklistEn : visitChecklistBn;
  String nextSlot(bool isEnglish) =>
      isEnglish ? availableSlotsEn.first : availableSlotsBn.first;
}

class DemoAppointment {
  final String id;
  final String specialistId;
  final String specialistNameBn;
  final String specialistNameEn;
  final String specialistSpecialtyBn;
  final String specialistSpecialtyEn;
  final String slotBn;
  final String slotEn;
  final bool isOnline;
  final bool vitalsShared;
  final DateTime bookedAt;

  const DemoAppointment({
    required this.id,
    required this.specialistId,
    required this.specialistNameBn,
    required this.specialistNameEn,
    required this.specialistSpecialtyBn,
    required this.specialistSpecialtyEn,
    required this.slotBn,
    required this.slotEn,
    required this.isOnline,
    required this.vitalsShared,
    required this.bookedAt,
  });

  String displayName(bool isEnglish) =>
      isEnglish ? specialistNameEn : specialistNameBn;
  String displaySpecialty(bool isEnglish) =>
      isEnglish ? specialistSpecialtyEn : specialistSpecialtyBn;
  String displaySlot(bool isEnglish) => isEnglish ? slotEn : slotBn;
}

// ── Seeded specialist data ────────────────────────────────────────────────────

const _seedSpecialists = <DemoSpecialist>[
  DemoSpecialist(
    id: 'specialist-amina',
    nameBn: 'ডা. আমিনা খাতুন',
    nameEn: 'Dr. Amina Khatun',
    specialtyBn: 'প্রসূতি ও স্ত্রীরোগ বিশেষজ্ঞ',
    specialtyEn: 'Obstetrics & Gynecology',
    hospitalBn: 'ঢাকা মেডিক্যাল কলেজ হাসপাতাল',
    hospitalEn: 'Dhaka Medical College Hospital',
    chamberBn: 'ইবনে সিনা ডায়াগনস্টিক, ধানমণ্ডি',
    chamberEn: 'Ibn Sina Diagnostic, Dhanmondi',
    addressBn: 'বকশীবাজার, ঢাকা ১০০০',
    addressEn: 'Bakshi Bazar, Dhaka 1000',
    fee: 800,
    languagesBn: ['বাংলা', 'ইংরেজি'],
    languagesEn: ['Bangla', 'English'],
    availableSlotsBn: [
      'আজ, বিকেল ৩:৩০',
      'আগামীকাল, সকাল ১০:০০',
      'আগামীকাল, দুপুর ২:০০',
      'পরশু, সকাল ১১:০০',
    ],
    availableSlotsEn: [
      'Today, 3:30 PM',
      'Tomorrow, 10:00 AM',
      'Tomorrow, 2:00 PM',
      'Day after tomorrow, 11:00 AM',
    ],
    hasOnlineConsultation: true,
    distanceBn: '৩.২ কিমি',
    distanceEn: '3.2 km',
    avatarInitials: 'AK',
    visitChecklistBn: [
      'পূর্ববর্তী প্রেসক্রিপশন',
      'আল্ট্রাসাউন্ড রিপোর্ট',
      'CBC / রক্ত পরীক্ষার রিপোর্ট',
      'রক্তচাপের লগ',
    ],
    visitChecklistEn: [
      'Previous prescriptions',
      'Ultrasound report',
      'CBC / Blood test report',
      'Blood pressure log',
    ],
  ),
  DemoSpecialist(
    id: 'specialist-rafiqul',
    nameBn: 'ডা. রফিকুল ইসলাম',
    nameEn: 'Dr. Rafiqul Islam',
    specialtyBn: 'ভ্রূণ চিকিৎসা ও উচ্চ-ঝুঁকি প্রসূতি বিশেষজ্ঞ',
    specialtyEn: 'Fetal Medicine & High-Risk Obstetrics',
    hospitalBn: 'স্কয়ার হাসপাতাল, পান্থপথ',
    hospitalEn: 'Square Hospital, Panthapath',
    chamberBn: 'স্কয়ার হাসপাতাল',
    chamberEn: 'Square Hospital',
    addressBn: '১৮/এফ বীর উত্তম কাজী নুরুজ্জামান সরক, ঢাকা ১২০৫',
    addressEn: '18/F Bir Uttam Qazi Nuruzzaman Sarak, Dhaka 1205',
    fee: 1500,
    languagesBn: ['বাংলা', 'ইংরেজি'],
    languagesEn: ['Bangla', 'English'],
    availableSlotsBn: [
      'আজ, বিকেল ৪:০০ (অনলাইন)',
      'আজ, বিকেল ৫:৩০',
      'আগামীকাল, সকাল ৯:৩০',
      'আগামীকাল, দুপুর ১২:০০',
    ],
    availableSlotsEn: [
      'Today, 4:00 PM (Online)',
      'Today, 5:30 PM',
      'Tomorrow, 9:30 AM',
      'Tomorrow, 12:00 PM',
    ],
    hasOnlineConsultation: true,
    distanceBn: '৫.৮ কিমি',
    distanceEn: '5.8 km',
    avatarInitials: 'RI',
    visitChecklistBn: [
      'পূর্ববর্তী প্রেসক্রিপশন',
      'আল্ট্রাসাউন্ড রিপোর্ট',
      'CBC / রক্ত পরীক্ষার রিপোর্ট',
      'রক্তচাপের লগ',
      '২৪ ঘণ্টার ইউরিন রিপোর্ট',
    ],
    visitChecklistEn: [
      'Previous prescriptions',
      'Ultrasound report',
      'CBC / Blood test report',
      'Blood pressure log',
      '24-hour urine report',
    ],
  ),
  DemoSpecialist(
    id: 'specialist-nasrin',
    nameBn: 'ডা. নাসরিন সুলতানা',
    nameEn: 'Dr. Nasrin Sultana',
    specialtyBn: 'পুষ্টি ও গর্ভকালীন ডায়াবেটিস বিশেষজ্ঞ',
    specialtyEn: 'Nutrition & Gestational Diabetes',
    hospitalBn: 'পপুলার মেডিক্যাল সেন্টার',
    hospitalEn: 'Popular Medical Centre',
    chamberBn: 'পপুলার মেডিক্যাল সেন্টার, ধানমণ্ডি',
    chamberEn: 'Popular Medical Centre, Dhanmondi',
    addressBn: 'হাউস ১৬, রোড ২, ধানমণ্ডি, ঢাকা ১২০৫',
    addressEn: 'House 16, Road 2, Dhanmondi, Dhaka 1205',
    fee: 600,
    languagesBn: ['বাংলা'],
    languagesEn: ['Bangla'],
    availableSlotsBn: [
      'পরশু, সকাল ১১:৩০',
      'পরশু, বিকেল ৪:০০',
      '৩ দিন পরে, সকাল ১০:০০',
    ],
    availableSlotsEn: [
      'Day after tomorrow, 11:30 AM',
      'Day after tomorrow, 4:00 PM',
      'In 3 days, 10:00 AM',
    ],
    hasOnlineConsultation: false,
    distanceBn: '২.১ কিমি',
    distanceEn: '2.1 km',
    avatarInitials: 'NS',
    visitChecklistBn: [
      'রক্তের গ্লুকোজ রিপোর্ট',
      'HbA1c রিপোর্ট',
      'পূর্ববর্তী পুষ্টি পরিকল্পনা (থাকলে)',
      'ওজনের লগ',
    ],
    visitChecklistEn: [
      'Blood glucose report',
      'HbA1c report',
      'Previous nutrition plan (if any)',
      'Weight log',
    ],
  ),
];

// ── Doctor-only models ────────────────────────────────────────────────────────

class DemoCareItem {
  final String id;
  final String patientId;
  final String text;
  final DateTime prescribedAt;

  const DemoCareItem({
    required this.id,
    required this.patientId,
    required this.text,
    required this.prescribedAt,
  });
}

class DemoReferral {
  final String id;
  final String patientId;
  final String specialistNameBn;
  final String specialistNameEn;
  final String specialistSpecialtyBn;
  final String specialistSpecialtyEn;
  final String reasonBn;
  final String reasonEn;
  final DateTime createdAt;

  const DemoReferral({
    required this.id,
    required this.patientId,
    required this.specialistNameBn,
    required this.specialistNameEn,
    required this.specialistSpecialtyBn,
    required this.specialistSpecialtyEn,
    required this.reasonBn,
    required this.reasonEn,
    required this.createdAt,
  });

  String displayName(bool en) => en ? specialistNameEn : specialistNameBn;
  String displaySpecialty(bool en) =>
      en ? specialistSpecialtyEn : specialistSpecialtyBn;
  String displayReason(bool en) => en ? reasonEn : reasonBn;
}

class DemoVitalsNudge {
  final String id;
  final String patientId;
  final String messageBn;
  final String messageEn;
  final DateTime requestedAt;

  const DemoVitalsNudge({
    required this.id,
    required this.patientId,
    required this.messageBn,
    required this.messageEn,
    required this.requestedAt,
  });

  String displayMessage(bool en) => en ? messageEn : messageBn;
}

class DemoVitalsAnnotation {
  final String id;
  final String patientId;
  final DateTime loggedAt;
  final String annotation;

  const DemoVitalsAnnotation({
    required this.id,
    required this.patientId,
    required this.loggedAt,
    required this.annotation,
  });
}

// ── Repository ────────────────────────────────────────────────────────────────

class DemoRepository extends ChangeNotifier {
  DemoRepository._();

  static final DemoRepository instance = DemoRepository._();
  static const _prefsSessionEmail = 'demo_session_email';
  static const _prefsSessionRole = 'demo_session_role';
  static const _demoPassword = 'Maternify@123';
  static const _uuid = Uuid();

  DemoSession? _session;
  late Patient _motherPatient;
  late List<VitalsLog> _vitalsLogs;
  late List<DemoAlert> _alerts;
  late List<DemoChatMessage> _chatMessages;
  late List<DemoProviderPatient> _providerPatients;
  late Map<String, dynamic> _seedData;
  late Map<String, dynamic> _nusratRecord;
  DemoRiskLevel _riskLevel = DemoRiskLevel.yellow;
  bool _sosTriggered = false;
  bool _isInitialized = false;
  DateTime? _lastVitalsUpdateAt;

  // Language toggle
  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;
  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  // Specialist & booking
  final List<DemoSpecialist> _specialists = List.of(_seedSpecialists);
  final List<DemoAppointment> _appointments = [];

  // All-patient records (for doctor view)
  late Map<String, List<VitalsLog>> _allPatientVitals;
  late Map<String, List<DemoTriageEvent>> _allTriageHistory;
  late Map<String, String> _allAiSummaries;

  // Doctor features
  final Map<String, DemoRiskLevel> _overriddenRisks = {};
  final List<DemoCareItem> _careItems = [];
  final List<DemoReferral> _referrals = [];
  final List<DemoVitalsAnnotation> _annotations = [];
  final List<DemoVitalsNudge> _nudges = [];

  List<DemoSpecialist> get specialists => List.unmodifiable(_specialists);
  List<DemoAppointment> get appointments => List.unmodifiable(_appointments);

  List<VitalsLog> getPatientVitals(String patientId) {
    if (patientId == _motherPatient.id) return vitalsLogs;
    return _allPatientVitals[patientId] ?? [];
  }

  List<DemoTriageEvent> getPatientTriageHistory(String patientId) {
    if (patientId == _motherPatient.id) {
      return (_allTriageHistory[patientId] ?? []);
    }
    return _allTriageHistory[patientId] ?? [];
  }

  String getPatientAiSummary(String patientId) {
    return _allAiSummaries[patientId] ?? '';
  }

  List<DemoCareItem> getCareItems(String patientId) =>
      _careItems.where((i) => i.patientId == patientId).toList();

  List<DemoReferral> getReferrals(String patientId) =>
      _referrals.where((r) => r.patientId == patientId).toList();

  DemoVitalsNudge? getNudge(String patientId) {
    final matches = _nudges.where((n) => n.patientId == patientId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  DemoVitalsAnnotation? getAnnotation(String patientId, DateTime loggedAt) {
    final matches = _annotations
        .where((a) => a.patientId == patientId && a.loggedAt == loggedAt)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> addDoctorNote({
    required String patientId,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _alerts = [
      DemoAlert(
        id: _uuid.v4(),
        title: _isEnglish ? 'Note from Clinic' : 'ক্লিনিক থেকে বার্তা',
        message: note,
        createdAt: DateTime.now(),
        riskLevel: DemoRiskLevel.green,
      ),
      ..._alerts,
    ];
    notifyListeners();
  }

  Future<void> broadcastToAllPatients(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _alerts = [
      DemoAlert(
        id: _uuid.v4(),
        title: _isEnglish ? 'Clinic Announcement' : 'ক্লিনিক বিজ্ঞপ্তি',
        message: message,
        createdAt: DateTime.now(),
        riskLevel: DemoRiskLevel.green,
      ),
      ..._alerts,
    ];
    notifyListeners();
  }

  Future<void> overridePatientRisk({
    required String patientId,
    required DemoRiskLevel newLevel,
    required String reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _overriddenRisks[patientId] = newLevel;
    if (patientId == _motherPatient.id) {
      _riskLevel = newLevel;
    }
    final levelLabel = _isEnglish
        ? switch (newLevel) {
            DemoRiskLevel.green => 'Stable',
            DemoRiskLevel.yellow => 'Watch Closely',
            DemoRiskLevel.red => 'Urgent',
          }
        : switch (newLevel) {
            DemoRiskLevel.green => 'স্থিতিশীল',
            DemoRiskLevel.yellow => 'নজরে রাখুন',
            DemoRiskLevel.red => 'জরুরি',
          };
    _alerts = [
      DemoAlert(
        id: _uuid.v4(),
        title: _isEnglish
            ? 'Risk Level Updated by Clinic'
            : 'ক্লিনিক ঝুঁকি স্তর পরিবর্তন করেছে',
        message: '$levelLabel — $reason',
        createdAt: DateTime.now(),
        riskLevel: newLevel,
      ),
      ..._alerts,
    ];
    _refreshProviderPatients();
    notifyListeners();
  }

  Future<void> prescribeCareItem({
    required String patientId,
    required String text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _careItems.insert(
      0,
      DemoCareItem(
        id: _uuid.v4(),
        patientId: patientId,
        text: text,
        prescribedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAlertReviewed(String alertId) {
    _alerts = _alerts
        .map((a) => a.id == alertId ? a.copyWithReviewed() : a)
        .toList();
    notifyListeners();
  }

  Future<void> referToSpecialist({
    required String patientId,
    required DemoSpecialist specialist,
    required String reasonBn,
    required String reasonEn,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _referrals.insert(
      0,
      DemoReferral(
        id: _uuid.v4(),
        patientId: patientId,
        specialistNameBn: specialist.nameBn,
        specialistNameEn: specialist.nameEn,
        specialistSpecialtyBn: specialist.specialtyBn,
        specialistSpecialtyEn: specialist.specialtyEn,
        reasonBn: reasonBn,
        reasonEn: reasonEn,
        createdAt: DateTime.now(),
      ),
    );
    _alerts = [
      DemoAlert(
        id: _uuid.v4(),
        title: _isEnglish ? 'Referral from Your Clinic' : 'ক্লিনিক রেফারেল',
        message: _isEnglish
            ? 'Your doctor has referred you to ${specialist.nameEn} (${specialist.specialtyEn}).'
            : 'আপনার চিকিৎসক আপনাকে ${specialist.nameBn} (${specialist.specialtyBn})-এর কাছে রেফার করেছেন।',
        createdAt: DateTime.now(),
        riskLevel: DemoRiskLevel.yellow,
      ),
      ..._alerts,
    ];
    notifyListeners();
  }

  Future<void> requestVitals(String patientId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _nudges.removeWhere((n) => n.patientId == patientId);
    _nudges.add(DemoVitalsNudge(
      id: _uuid.v4(),
      patientId: patientId,
      messageBn: 'আপনার চিকিৎসক আজকের ভাইটালস লগ করতে বলেছেন।',
      messageEn: "Your doctor is requesting today's vitals reading.",
      requestedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void dismissNudge(String patientId) {
    _nudges.removeWhere((n) => n.patientId == patientId);
    notifyListeners();
  }

  Future<void> annotateReading({
    required String patientId,
    required DateTime loggedAt,
    required String annotation,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _annotations.removeWhere(
        (a) => a.patientId == patientId && a.loggedAt == loggedAt);
    _annotations.add(DemoVitalsAnnotation(
      id: _uuid.v4(),
      patientId: patientId,
      loggedAt: loggedAt,
      annotation: annotation,
    ));
    notifyListeners();
  }

  DemoSession? get session => _session;
  Patient get motherPatient => _motherPatient;
  List<VitalsLog> get vitalsLogs => List.unmodifiable(_vitalsLogs);
  List<DemoAlert> get alerts => List.unmodifiable(_alerts);
  List<DemoChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<DemoProviderPatient> get providerPatients =>
      List.unmodifiable(_providerPatients);
  DemoRiskLevel get currentRiskLevel => _riskLevel;
  bool get sosTriggered => _sosTriggered;
  DateTime? get lastVitalsUpdateAt => _lastVitalsUpdateAt;

  VitalsLog get latestVitals => _vitalsLogs.last;

  String get riskLabel => switch (_riskLevel) {
        DemoRiskLevel.green => 'Stable',
        DemoRiskLevel.yellow => 'Watch Closely',
        DemoRiskLevel.red => 'Immediate Attention',
      };

  String get riskLabelBangla => _isEnglish
      ? riskLabel
      : switch (_riskLevel) {
          DemoRiskLevel.green => 'স্থিতিশীল',
          DemoRiskLevel.yellow => 'নজরে রাখা দরকার',
          DemoRiskLevel.red => 'তাৎক্ষণিক মনোযোগ দরকার',
        };

  String get riskSummaryBangla {
    if (_isEnglish) {
      if (_sosTriggered) {
        return 'SOS dispatched. Your clinic team and emergency contact have been alerted.';
      }
      return switch (_riskLevel) {
        DemoRiskLevel.green =>
          "Today's readings are stable. Keep logging regularly.",
        DemoRiskLevel.yellow =>
          'Blood pressure has been gradually rising over the past 7 days. Log another check today.',
        DemoRiskLevel.red =>
          'Dizziness, blurred vision, and elevated blood pressure together indicate you need urgent assessment now.',
      };
    }
    if (_sosTriggered) {
      return 'SOS পাঠানো হয়েছে। ক্লিনিক টিম ও জরুরি পরিচিতিকে সতর্ক করা হয়েছে।';
    }
    return switch (_riskLevel) {
      DemoRiskLevel.green => 'আজকের রিডিং স্থিতিশীল আছে। নিয়মিত লগ চালিয়ে যান।',
      DemoRiskLevel.yellow =>
        'গত ৭ দিনে রক্তচাপ একটু একটু করে বেড়েছে। আজকেই আরেকটি চেক লগ করুন।',
      DemoRiskLevel.red =>
        'মাথা ঘোরা, ঝাপসা দেখা এবং উচ্চ রক্তচাপ একসাথে থাকায় এখন জরুরি মূল্যায়ন দরকার।',
    };
  }

  String get aiSummaryBangla {
    final latest = latestVitals;
    final weekAgo = _vitalsLogs[_vitalsLogs.length - 7];
    if (_isEnglish) {
      return 'Over the past 7 days, BP has risen from '
          '${weekAgo.systolicBp}/${weekAgo.diastolicBp} to '
          '${latest.systolicBp}/${latest.diastolicBp}. '
          'Kick count is at ${latest.kickCount}, '
          'and today\'s symptom report has increased risk.';
    }
    return 'গত ৭ দিনে রক্তচাপ ${weekAgo.systolicBp}/${weekAgo.diastolicBp} থেকে '
        '${latest.systolicBp}/${latest.diastolicBp}-এ উঠেছে, কিক কাউন্ট ${latest.kickCount}-এ নেমেছে, '
        'এবং আজকের উপসর্গ রিপোর্ট ঝুঁকি বাড়িয়েছে।';
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadSeed();
    _isInitialized = true;
  }

  Future<DemoSession?> restoreSession() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_prefsSessionEmail);
    final roleName = prefs.getString(_prefsSessionRole);
    if (email == null || roleName == null) return null;

    final role = roleName == 'doctor' ? DemoRole.doctor : DemoRole.mother;
    _session = _sessionFor(email: email, role: role);
    return _session;
  }

  Future<DemoSession> signIn({
    required String email,
    required String password,
    required DemoRole selectedRole,
  }) async {
    await initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    if (password != _demoPassword) {
      throw Exception(_isEnglish
          ? 'Incorrect password. Please try again.'
          : 'পাসওয়ার্ড ভুল হয়েছে। আবার চেষ্টা করুন।');
    }

    final normalized = email.trim().toLowerCase();
    final account = _accountFor(selectedRole);
    final expected = account['email'] as String;

    if (normalized != expected) {
      throw Exception(selectedRole == DemoRole.mother
          ? (_isEnglish
              ? 'Please use the correct email for the mother profile.'
              : 'মা প্রোফাইলে প্রবেশের জন্য সঠিক ইমেইল ব্যবহার করুন।')
          : (_isEnglish
              ? 'Please use the correct email for the doctor profile.'
              : 'চিকিৎসক প্রোফাইলে প্রবেশের জন্য সঠিক ইমেইল ব্যবহার করুন।'));
    }

    _session = _sessionFor(email: normalized, role: selectedRole);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSessionEmail, normalized);
    await prefs.setString(
      _prefsSessionRole,
      selectedRole == DemoRole.doctor ? 'doctor' : 'mother',
    );
    notifyListeners();
    return _session!;
  }

  Future<void> signOut() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsSessionEmail);
    await prefs.remove(_prefsSessionRole);
    notifyListeners();
  }

  Future<Patient> loadPatient(String patientId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (_motherPatient.id != patientId) {
      throw Exception(_isEnglish
          ? 'Patient record not found.'
          : 'রোগীর তথ্য পাওয়া যায়নি৷');
    }
    return _motherPatient;
  }

  Future<List<VitalsLog>> loadVitals(String patientId) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (_motherPatient.id != patientId) return <VitalsLog>[];
    return List<VitalsLog>.from(_vitalsLogs);
  }

  Future<VitalsLog> submitVitals(VitalsLog log) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _vitalsLogs = [..._vitalsLogs, log]
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    _lastVitalsUpdateAt = log.loggedAt;
    _recalculateRiskFromVitals(log);
    _refreshProviderPatients();
    notifyListeners();
    return log;
  }

  Future<DemoTriageResponse> submitTriage({
    required String patientId,
    required String text,
    required String lang,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (_motherPatient.id != patientId) {
      throw Exception(_isEnglish
          ? 'Unable to analyze symptoms. Please try again.'
          : 'লক্ষণ বিশ্লেষণ সম্ভব হয়নি৷ আবার চেষ্টা করুন৷');
    }

    final normalized = text.toLowerCase();
    final isRed = normalized.contains('মাথা ঘুর') ||
        normalized.contains('ঝাপসা') ||
        normalized.contains('blur') ||
        normalized.contains('vision') ||
        normalized.contains('dizziness') ||
        normalized.contains('headache');
    final isYellow = normalized.contains('পা ফুল') ||
        normalized.contains('swelling') ||
        normalized.contains('শ্বাস') ||
        normalized.contains('breathing');

    final tier = isRed
        ? TriageTier.red
        : isYellow
            ? TriageTier.yellow
            : TriageTier.green;
    final risk = isRed
        ? DemoRiskLevel.red
        : isYellow
            ? DemoRiskLevel.yellow
            : DemoRiskLevel.green;

    final latest = latestVitals;
    final message = DemoChatMessage(
      id: _uuid.v4(),
      text: _isEnglish
          ? switch (tier) {
              TriageTier.red =>
                'This is an urgent situation. Your latest BP is '
                    '${latest.systolicBp}/${latest.diastolicBp} mmHg and kick count is '
                    '${latest.kickCount} — these symptoms are concerning together. '
                    'Go to the nearest hospital now, do not be alone, and press SOS.',
              TriageTier.yellow =>
                'Based on today\'s symptoms and recent readings, please contact '
                    'your clinic within 24 hours. Measure BP again, rest, and seek '
                    'urgent care if symptoms worsen.',
              TriageTier.green =>
                'No immediate warning signs right now. Rest, stay hydrated, '
                    'and let us know if you experience dizziness, blurred vision, '
                    'abdominal pain, or reduced fetal movement.',
            }
          : switch (tier) {
              TriageTier.red =>
                'এটি জরুরি অবস্থা। আপনার সর্বশেষ BP ${latest.systolicBp}/${latest.diastolicBp} mmHg এবং কিক কাউন্ট ${latest.kickCount} দেখে এই লক্ষণগুলো উদ্বেগজনক। '
                    'এখনই নিকটস্থ হাসপাতালে যান, একা থাকবেন না, এবং SOS চাপুন।',
              TriageTier.yellow =>
                'আজকের লক্ষণ এবং সাম্প্রতিক রিডিং দেখে ২৪ ঘণ্টার মধ্যে ক্লিনিকে যোগাযোগ করুন। আবার BP মাপুন, বিশ্রাম নিন, এবং লক্ষণ বাড়লে জরুরি সহায়তা নিন।',
              TriageTier.green =>
                'এখনই জরুরি সংকেত দেখা যাচ্ছে না। বিশ্রাম নিন, পানি পান করুন, এবং মাথা ঘোরা, ঝাপসা দেখা, পেটব্যথা বা কিক কম হলে আবার জানান।',
            },
      isUser: false,
      timestamp: DateTime.now(),
      tier: tier,
      escalationRequired: tier == TriageTier.red,
    );

    _chatMessages = [
      ..._chatMessages,
      DemoChatMessage(
        id: _uuid.v4(),
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ),
      message,
    ];

    _riskLevel = _priorityRisk(_riskLevel, risk);
    if (tier == TriageTier.red) {
      _alerts = [
        DemoAlert(
          id: _uuid.v4(),
          title: _isEnglish ? 'Urgent Symptom Alert' : 'জরুরি লক্ষণ সতর্কতা',
          message: _isEnglish
              ? '${_motherPatient.name} reported dizziness and blurred vision. Clinic team has been flagged for immediate review.'
              : '${_motherPatient.name} মাথা ঘোরা ও ঝাপসা দেখার লক্ষণ জানিয়েছেন। ক্লিনিক টিমকে তাৎক্ষণিক পর্যালোচনার জন্য সতর্ক করা হয়েছে।',
          createdAt: DateTime.now(),
          riskLevel: DemoRiskLevel.red,
          urgent: true,
        ),
        ..._alerts,
      ];
    }
    _refreshProviderPatients();
    notifyListeners();
    return DemoTriageResponse(message: message, updatedRisk: _riskLevel);
  }

  Future<DemoSosResult> triggerSos() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    _sosTriggered = true;
    _riskLevel = DemoRiskLevel.red;
    _alerts = [
      DemoAlert(
        id: _uuid.v4(),
        title: _isEnglish ? 'SOS Dispatched' : 'SOS পাঠানো হয়েছে',
        message: _isEnglish
            ? 'Emergency information sent to the clinic team and emergency contact.'
            : 'জরুরি তথ্য ক্লিনিক টিম এবং পরিবারের পরিচিতিতে পাঠানো হয়েছে।',
        createdAt: DateTime.now(),
        riskLevel: DemoRiskLevel.red,
        urgent: true,
      ),
      ..._alerts,
    ];
    _refreshProviderPatients();
    notifyListeners();

    return DemoSosResult(
      statusLine: _isEnglish ? 'Emergency request active' : 'জরুরি অনুরোধ সক্রিয়',
      summary: _isEnglish
          ? 'SOS sent to your clinic team and emergency contact.'
          : 'আপনার ক্লিনিক টিম এবং জরুরি পরিচিতিকে SOS পাঠানো হয়েছে।',
      steps: _isEnglish
          ? [
              'Latest BP and kick count attached',
              'Patient location recorded',
              '${_motherPatient.name} flagged as high-priority patient',
            ]
          : [
              'সর্বশেষ BP এবং কিক কাউন্ট সংযুক্ত হয়েছে',
              'রোগীর অবস্থান রেকর্ড করা হয়েছে',
              '${_motherPatient.name} উচ্চ অগ্রাধিকার রোগী হিসেবে চিহ্নিত হয়েছেন',
            ],
    );
  }

  Future<void> simulateVoiceInput() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _chatMessages = [
      ..._chatMessages,
      DemoChatMessage(
        id: _uuid.v4(),
        text: _isEnglish
            ? '"I have dizziness and blurred vision"'
            : '"মাথা ঘুরছে আর চোখে ঝাপসা দেখছি"',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];
    notifyListeners();
  }

  // ── Specialist booking ────────────────────────────────────────────────────

  Future<DemoAppointment> bookAppointment({
    required DemoSpecialist specialist,
    required int slotIndex,
    required bool isOnline,
    required bool shareVitals,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final appointment = DemoAppointment(
      id: _uuid.v4(),
      specialistId: specialist.id,
      specialistNameBn: specialist.nameBn,
      specialistNameEn: specialist.nameEn,
      specialistSpecialtyBn: specialist.specialtyBn,
      specialistSpecialtyEn: specialist.specialtyEn,
      slotBn: specialist.availableSlotsBn[slotIndex],
      slotEn: specialist.availableSlotsEn[slotIndex],
      isOnline: isOnline,
      vitalsShared: shareVitals,
      bookedAt: DateTime.now(),
    );
    _appointments.insert(0, appointment);
    notifyListeners();
    return appointment;
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _loadSeed() async {
    final raw = await rootBundle.loadString('assets/demo/demo_seed.json');
    _seedData = jsonDecode(raw) as Map<String, dynamic>;

    final patients = _seedPatients;
    final nusratJson =
        patients.firstWhere((patient) => patient['id'] == 'patient-nusrat');

    _motherPatient = Patient.fromJson(nusratJson);
    _nusratRecord = (_seedData['patient_records']
        as Map<String, dynamic>)[_motherPatient.id] as Map<String, dynamic>;

    _vitalsLogs = (_nusratRecord['vitals'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(VitalsLog.fromJson)
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    _chatMessages = (_seedData['chat_seed'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (item) => DemoChatMessage(
            id: item['id'] as String,
            text: item['text'] as String,
            isUser: item['is_user'] as bool,
            timestamp: DateTime.parse(item['timestamp'] as String),
          ),
        )
        .toList();

    _alerts = (_seedData['alerts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_alertFromJson)
        .toList();

    _riskLevel = _riskFromString(nusratJson['risk_tier'] as String? ?? 'green');
    _sosTriggered = false;
    _lastVitalsUpdateAt = null;
    _providerPatients = _seedPatients.map(_providerPatientFromJson).toList();

    // Load all-patient data for doctor view
    final allRecords =
        _seedData['patient_records'] as Map<String, dynamic>;
    _allPatientVitals = {};
    _allTriageHistory = {};
    _allAiSummaries = {};
    for (final entry in allRecords.entries) {
      final rec = entry.value as Map<String, dynamic>;
      _allPatientVitals[entry.key] =
          ((rec['vitals'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
              .map(VitalsLog.fromJson)
              .toList()
            ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      _allTriageHistory[entry.key] =
          ((rec['triage_history'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>()
              .map(_triageEventFromJson)
              .toList();
      _allAiSummaries[entry.key] =
          rec['ai_summary'] as String? ?? '';
    }
  }

  DemoSession _sessionFor({
    required String email,
    required DemoRole role,
  }) {
    final account = _accountFor(role);
    return DemoSession(
      id: account['id'] as String,
      name: account['name'] as String,
      email: email.isEmpty ? account['email'] as String : email,
      role: role,
      patientId: account['patient_id'] as String?,
    );
  }

  Map<String, dynamic> _accountFor(DemoRole role) {
    return (_seedData['accounts'] as Map<String, dynamic>)[
        role == DemoRole.mother ? 'mother' : 'doctor'] as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> get _seedPatients =>
      (_seedData['patients'] as List<dynamic>).cast<Map<String, dynamic>>();

  void _recalculateRiskFromVitals(VitalsLog log) {
    if (log.systolicBp >= 145 || log.diastolicBp >= 95 || log.kickCount <= 7) {
      _riskLevel = DemoRiskLevel.red;
      _alerts = [
        DemoAlert(
          id: _uuid.v4(),
          title: _isEnglish ? 'Critical Reading Recorded' : 'জরুরি রিডিং লগ হয়েছে',
          message: _isEnglish
              ? 'BP ${log.systolicBp}/${log.diastolicBp} and kick count ${log.kickCount} recorded. Clinic team has been alerted.'
              : 'BP ${log.systolicBp}/${log.diastolicBp} এবং কিক কাউন্ট ${log.kickCount} রিডিং রেকর্ড হয়েছে। ক্লিনিক টিমকে সতর্ক করা হয়েছে।',
          createdAt: DateTime.now(),
          riskLevel: DemoRiskLevel.red,
          urgent: true,
        ),
        ..._alerts,
      ];
      return;
    }

    if (log.systolicBp >= 135 || log.diastolicBp >= 88 || log.kickCount <= 9) {
      _riskLevel = _priorityRisk(_riskLevel, DemoRiskLevel.yellow);
      _alerts = [
        DemoAlert(
          id: _uuid.v4(),
          title: _isEnglish ? 'Reading Updated' : 'রিডিং আপডেট হয়েছে',
          message: _isEnglish
              ? 'New reading saved. Your clinic team can now see your latest data.'
              : 'নতুন রিডিং সেভ হয়েছে। ক্লিনিক টিম আপনার তথ্য দেখতে পারছেন।',
          createdAt: DateTime.now(),
          riskLevel: DemoRiskLevel.yellow,
        ),
        ..._alerts,
      ];
    }
  }

  DemoRiskLevel _priorityRisk(DemoRiskLevel current, DemoRiskLevel next) {
    if (current == DemoRiskLevel.red || next == DemoRiskLevel.red) {
      return DemoRiskLevel.red;
    }
    if (current == DemoRiskLevel.yellow || next == DemoRiskLevel.yellow) {
      return DemoRiskLevel.yellow;
    }
    return DemoRiskLevel.green;
  }

  void _refreshProviderPatients() {
    final latest = latestVitals;
    _providerPatients = [
      DemoProviderPatient(
        id: _motherPatient.id,
        name: _motherPatient.name,
        weeksGestation: _motherPatient.weeksGestation,
        riskLevel: _overriddenRisks[_motherPatient.id] ?? _riskLevel,
        latestBp: '${latest.systolicBp}/${latest.diastolicBp}',
        summary: _sosTriggered
            ? (_isEnglish
                ? 'SOS active. Urgent alert sent to clinic team.'
                : 'SOS সক্রিয়। ক্লিনিক টিমকে জরুরি সতর্কতা পাঠানো হয়েছে।')
            : riskSummaryBangla,
        daysSinceLog: 0,
      ),
      ..._providerPatients.where((p) => p.id != _motherPatient.id).map(
            (p) => _overriddenRisks.containsKey(p.id)
                ? DemoProviderPatient(
                    id: p.id,
                    name: p.name,
                    weeksGestation: p.weeksGestation,
                    riskLevel: _overriddenRisks[p.id]!,
                    latestBp: p.latestBp,
                    summary: p.summary,
                    daysSinceLog: p.daysSinceLog,
                  )
                : p,
          ),
    ];
  }

  DemoAlert _alertFromJson(Map<String, dynamic> json) {
    final alertType = json['alert_type'] as String? ?? '';
    final title = switch (alertType) {
      'red_triage' => 'জরুরি লক্ষণ সতর্কতা',
      'sos_active' => 'SOS পাঠানো হয়েছে',
      'kick_count_low' => 'কিক কাউন্ট স্বাভাবিকের চেয়ে কম',
      _ => 'স্বাস্থ্য সতর্কতা',
    };

    return DemoAlert(
      id: json['id'] as String,
      title: title,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      riskLevel: _riskFromString(
        alertType == 'kick_count_low' ? 'yellow' : 'red',
      ),
      urgent: alertType == 'red_triage' || alertType == 'sos_active',
    );
  }

  DemoProviderPatient _providerPatientFromJson(Map<String, dynamic> json) {
    return DemoProviderPatient(
      id: json['id'] as String,
      name: json['name'] as String,
      weeksGestation: json['weeks_gestation'] as int,
      riskLevel: _riskFromString(json['risk_tier'] as String? ?? 'green'),
      latestBp: '${json['latest_systolic']}/${json['latest_diastolic']}',
      summary: json['summary'] as String? ?? '',
      daysSinceLog: json['days_since_log'] as int? ?? 0,
    );
  }

  DemoTriageEvent _triageEventFromJson(Map<String, dynamic> json) {
    return DemoTriageEvent(
      id: json['id'] as String,
      inputText: json['input_text'] as String,
      tier: json['triage_tier'] as String? ?? 'green',
      adviceBangla: json['advice_bangla'] as String? ?? '',
      adviceEnglish: json['advice_english'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      escalationRequired: json['escalation_required'] as bool? ?? false,
    );
  }

  DemoRiskLevel _riskFromString(String value) {
    switch (value) {
      case 'red':
        return DemoRiskLevel.red;
      case 'yellow':
        return DemoRiskLevel.yellow;
      default:
        return DemoRiskLevel.green;
    }
  }
}
