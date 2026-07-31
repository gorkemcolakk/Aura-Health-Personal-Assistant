class BreathLog {
  const BreathLog({
    required this.id,
    required this.timestamp,
    required this.durationMinutes,
  });

  factory BreathLog.fromJson(Map<String, dynamic> json) {
    return BreathLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      durationMinutes: json['durationMinutes'] as int,
    );
  }

  final String id;
  final DateTime timestamp;
  final int durationMinutes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  BreathLog copyWith({
    String? id,
    DateTime? timestamp,
    int? durationMinutes,
  }) {
    return BreathLog(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
