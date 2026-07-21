import 'dart:convert';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.notes,
    required this.enabled,
    this.lastTakenDate,
    this.mealTiming = 'Farketmez',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
  });

  factory Medication.fromMap(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      lastTakenDate: json['lastTakenDate'] as String?,
      mealTiming: json['mealTiming'] as String? ?? 'Farketmez',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.cast<int>() ??
          const [1, 2, 3, 4, 5, 6, 7],
    );
  }

  final String id;
  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final String notes;
  final bool enabled;
  final String? lastTakenDate;
  final String mealTiming;
  final List<int> daysOfWeek;

  int get notificationId => id.hashCode & 0x7fffffff;

  bool get isTakenToday {
    if (lastTakenDate == null) return false;
    final today = DateTime.now().toIso8601String().split('T').first;
    return lastTakenDate == today;
  }

  String get timeLabel {
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hourText:$minuteText';
  }

  Medication copyWith({
    String? name,
    String? dosage,
    int? hour,
    int? minute,
    String? notes,
    bool? enabled,
    String? lastTakenDate,
    String? mealTiming,
    List<int>? daysOfWeek,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      notes: notes ?? this.notes,
      enabled: enabled ?? this.enabled,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
      mealTiming: mealTiming ?? this.mealTiming,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'hour': hour,
      'minute': minute,
      'notes': notes,
      'enabled': enabled,
      'lastTakenDate': lastTakenDate,
      'mealTiming': mealTiming,
      'daysOfWeek': daysOfWeek,
    };
  }

  static String encodeList(List<Medication> medications) {
    return jsonEncode(medications.map((item) => item.toMap()).toList());
  }

  static List<Medication> decodeList(String source) {
    final items = jsonDecode(source) as List<dynamic>;
    return items
        .map((item) => Medication.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
