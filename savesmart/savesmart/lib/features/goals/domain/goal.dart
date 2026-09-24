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
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Savings goal',
    icon: json['icon']?.toString() ?? 'savings',
    targetPaise: (json['targetPaise'] as num).toInt(),
    savedPaise: (json['savedPaise'] as num).toInt(),
    targetDate:
        DateTime.tryParse(json['targetDate']?.toString() ?? '') ??
        DateTime.now(),
    status: json['status']?.toString() ?? 'active',
    progressPct: (json['progressPct'] as num).toDouble(),
    requiredMonthlyPaise: (json['requiredMonthlyPaise'] as num).toInt(),
  );
}
