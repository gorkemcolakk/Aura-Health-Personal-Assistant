import 'dart:convert';

import 'sleep_log.dart';
import 'water_log.dart';

enum ActivityLevel {
  low('Düşük', 0),
  balanced('Dengeli', 350),
  active('Aktif', 650),
  athletic('Yoğun', 900);

  const ActivityLevel(this.label, this.waterBoostMl);

  final String label;
  final int waterBoostMl;
}

class HealthProfile {
  const HealthProfile({
    required this.name,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.healthGoal,
    required this.conditions,
    required this.waterConsumedMl,
    required this.waterLogs,
    required this.sleepLogs,
    this.bloodType = '',
    this.allergies = '',
    this.emergencyContact = '',
    this.emergencyPhone = '',
    this.sleepTargetHours = 8,
    this.gender = 'Belirtilmedi',
  });

  factory HealthProfile.initial({String name = '', String gender = 'Belirtilmedi', String birthDate = ''}) {
    return HealthProfile(
      name: name,
      gender: gender,
      birthDate: birthDate,
      heightCm: 0,
      weightKg: 0,
      activity: ActivityLevel.balanced,
      healthGoal: '',
      conditions: '',
      waterConsumedMl: 0,
      waterLogs: const [],
      sleepLogs: const [],
    );
  }

  factory HealthProfile.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return HealthProfile(
      name: json['name'] as String? ?? '',
      birthDate: _parseOrCalculateBirthDate(json),
      heightCm: (json['heightCm'] as num? ?? 0).toDouble(),
      weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
      activity: ActivityLevel.values.firstWhere(
        (item) => item.name == json['activity'],
        orElse: () => ActivityLevel.balanced,
      ),
      healthGoal: json['healthGoal'] as String? ?? '',
      conditions: json['conditions'] as String? ?? '',
      waterConsumedMl: json['waterConsumedMl'] as int? ?? 0,
      waterLogs: json['waterLogs'] == null
          ? const <WaterLog>[]
          : (json['waterLogs'] as List<dynamic>)
              .map((item) => WaterLog.fromJson(item as Map<String, dynamic>))
              .toList(),
      sleepLogs: json['sleepLogs'] == null
          ? const <SleepLog>[]
          : (json['sleepLogs'] as List<dynamic>)
              .map((item) => SleepLog.fromJson(item as Map<String, dynamic>))
              .toList(),
      bloodType: json['bloodType'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      emergencyContact: json['emergencyContact'] as String? ?? '',
      emergencyPhone: json['emergencyPhone'] as String? ?? '',
      sleepTargetHours: (json['sleepTargetHours'] as num?)?.toDouble() ?? 8,
      gender: json['gender'] as String? ?? 'Belirtilmedi',
    );
  }

  final String name;
  final String gender;
  final String birthDate;

  int get age {
    if (birthDate.isEmpty) return 0;
    try {
      final bd = DateTime.parse(birthDate);
      final today = DateTime.now();
      int a = today.year - bd.year;
      if (today.month < bd.month || (today.month == bd.month && today.day < bd.day)) {
        a--;
      }
      return a > 0 ? a : 0;
    } catch (_) {
      return 0;
    }
  }

  static String _parseOrCalculateBirthDate(Map<String, dynamic> json) {
    final bdJson = json['birthDate'] as String?;
    if (bdJson != null && bdJson.isNotEmpty) {
      return bdJson;
    }
    final ageJson = json['age'] as int?;
    if (ageJson != null && ageJson > 0) {
      return DateTime(DateTime.now().year - ageJson, 1, 1).toIso8601String().split('T').first;
    }
    return '';
  }
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final String healthGoal;
  final String conditions;
  final int waterConsumedMl;
  final List<WaterLog> waterLogs;
  final List<SleepLog> sleepLogs;
  final String bloodType;
  final String allergies;
  final String emergencyContact;
  final String emergencyPhone;
  final double sleepTargetHours;

  static String formatToDisplay(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return dateStr;
  }

  static String formatToIso(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dateStr;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'AH';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  HealthProfile copyWith({
    String? name,
    String? gender,
    String? birthDate,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    String? healthGoal,
    String? conditions,
    int? waterConsumedMl,
    List<WaterLog>? waterLogs,
    List<SleepLog>? sleepLogs,
    String? bloodType,
    String? allergies,
    String? emergencyContact,
    String? emergencyPhone,
    double? sleepTargetHours,
  }) {
    return HealthProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      healthGoal: healthGoal ?? this.healthGoal,
      conditions: conditions ?? this.conditions,
      waterConsumedMl: waterConsumedMl ?? this.waterConsumedMl,
      waterLogs: waterLogs ?? this.waterLogs,
      sleepLogs: sleepLogs ?? this.sleepLogs,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      sleepTargetHours: sleepTargetHours ?? this.sleepTargetHours,
    );
  }

  String toJson() {
    return jsonEncode({
      'name': name,
      'gender': gender,
      'birthDate': birthDate,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activity': activity.name,
      'healthGoal': healthGoal,
      'conditions': conditions,
      'waterConsumedMl': waterConsumedMl,
      'waterLogs': waterLogs.map((item) => item.toJson()).toList(),
      'sleepLogs': sleepLogs.map((item) => item.toJson()).toList(),
      'bloodType': bloodType,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'sleepTargetHours': sleepTargetHours,
    });
  }
}
