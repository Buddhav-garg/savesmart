class AutoSaveRule {
  const AutoSaveRule({
    required this.id,
    required this.goalId,
    required this.type,
    required this.amountPaise,
    required this.percent,
    required this.schedule,
    required this.paused,
    required this.pausedSince,
  });

  final String id;
  final String goalId;
  final String type;
  final int? amountPaise;
  final double? percent;
  final String? schedule;
  final bool paused;
  final DateTime? pausedSince;

  factory AutoSaveRule.fromJson(Map<String, dynamic> json) => AutoSaveRule(
    id: json['id']?.toString() ?? '',
    goalId: json['goalId']?.toString() ?? '',
    type: json['type']?.toString() ?? 'round_up',
    amountPaise: (json['amountPaise'] as num?)?.toInt(),
    percent: (json['percent'] as num?)?.toDouble(),
    schedule: json['schedule'] as String?,
    paused: json['paused'] as bool? ?? false,
    pausedSince: json['pausedSince'] == null
        ? null
        : DateTime.tryParse(json['pausedSince']?.toString() ?? ''),
  );
}
