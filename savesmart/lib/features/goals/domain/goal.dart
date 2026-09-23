class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetPaise,
    required this.savedPaise,
    required this.targetDate,
    required this.status,
    required this.progressPct,
    required this.requiredMonthlyPaise,
  });

  final String id;
  final String name;
  final String icon;
  final int targetPaise;
  final int savedPaise;
  final DateTime targetDate;
  final String status;
  final double progressPct;
  final int requiredMonthlyPaise;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? 'savings',
    targetPaise: (json['targetPaise'] as num).toInt(),
    savedPaise: (json['savedPaise'] as num).toInt(),
    targetDate: DateTime.parse(json['targetDate'] as String),
    status: json['status'] as String,
    progressPct: (json['progressPct'] as num).toDouble(),
    requiredMonthlyPaise: (json['requiredMonthlyPaise'] as num).toInt(),
  );
}
