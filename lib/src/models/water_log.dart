class WaterLog {
  const WaterLog({
    required this.id,
    required this.timestamp,
    required this.amountMl,
  });

  factory WaterLog.fromJson(Map<String, dynamic> json) {
    return WaterLog(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amountMl: json['amountMl'] as int,
    );
  }

  final String id;
  final DateTime timestamp;
  final int amountMl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amountMl': amountMl,
    };
  }
}
