import 'package:equatable/equatable.dart';

class Patient extends Equatable {
  final String id;
  final String name;
  final int age;
  final String phone;
  final int gravida;
  final int parity;
  final int weeksGestation;
  final String bloodType;
  final String providerId;
  final DateTime createdAt;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.gravida,
    required this.parity,
    required this.weeksGestation,
    required this.bloodType,
    required this.providerId,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        id: json['id'] as String,
        name: json['name'] as String,
        age: json['age'] as int,
        phone: json['phone'] as String,
        gravida: json['gravida'] as int,
        parity: json['parity'] as int,
        weeksGestation: json['weeks_gestation'] as int,
        bloodType: json['blood_type'] as String,
        providerId: json['provider_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'phone': phone,
        'gravida': gravida,
        'parity': parity,
        'weeks_gestation': weeksGestation,
        'blood_type': bloodType,
        'provider_id': providerId,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id];
}
