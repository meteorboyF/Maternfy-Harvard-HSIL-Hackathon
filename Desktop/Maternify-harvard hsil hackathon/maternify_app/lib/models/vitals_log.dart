import 'package:equatable/equatable.dart';

class VitalsLog extends Equatable {
  final String id;
  final String patientId;
  final int systolicBp;
  final int diastolicBp;
  final double weightKg;
  final double bloodGlucose;
  final int kickCount;
  final DateTime loggedAt;

  const VitalsLog({
    required this.id,
    required this.patientId,
    required this.systolicBp,
    required this.diastolicBp,
    required this.weightKg,
    required this.bloodGlucose,
    required this.kickCount,
    required this.loggedAt,
  });

  factory VitalsLog.fromJson(Map<String, dynamic> json) => VitalsLog(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        systolicBp: json['systolic_bp'] as int,
        diastolicBp: json['diastolic_bp'] as int,
        weightKg: (json['weight_kg'] as num).toDouble(),
        bloodGlucose: (json['blood_glucose'] as num).toDouble(),
        kickCount: json['kick_count'] as int,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'weight_kg': weightKg,
        'blood_glucose': bloodGlucose,
        'kick_count': kickCount,
        'logged_at': loggedAt.toIso8601String(),
      };

  bool get isBpElevated => systolicBp >= 140 || diastolicBp >= 90;

  @override
  List<Object?> get props => [id];
}
