class MoodLog {
  const MoodLog({
    required this.id,
    required this.timestamp,
    required this.moodLevel,
    this.symptoms = const [],
    this.note = '',
  });

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      moodLevel: json['moodLevel'] as int,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      note: json['note'] as String? ?? '',
    );
  }

  final String id;
  final DateTime timestamp;
  final int moodLevel; // 1 to 5 (1: Very Bad, 5: Excellent)
  final List<String> symptoms;
  final String note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'moodLevel': moodLevel,
      'symptoms': symptoms,
      'note': note,
    };
  }

  MoodLog copyWith({
    String? id,
    DateTime? timestamp,
    int? moodLevel,
    List<String>? symptoms,
    String? note,
  }) {
    return MoodLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      moodLevel: moodLevel ?? this.moodLevel,
      symptoms: symptoms ?? this.symptoms,
      note: note ?? this.note,
    );
  }
}
