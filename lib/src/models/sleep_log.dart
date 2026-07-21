class SleepLog {
  const SleepLog({
    required this.date,
    required this.hours,
    required this.feeling,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num).toDouble(),
      feeling: json['feeling'] as String,
    );
  }

  final DateTime date;
  final double hours;
  final String feeling;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'hours': hours,
      'feeling': feeling,
    };
  }
}
