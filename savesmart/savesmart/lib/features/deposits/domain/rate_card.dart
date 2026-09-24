class RateCard {
  const RateCard({
    required this.kind,
    required this.minTenureDays,
    required this.maxTenureDays,
    required this.ratePct,
    required this.seniorBonusPct,
  });

  final String kind;
  final int minTenureDays;
  final int maxTenureDays;
  final double ratePct;
  final double seniorBonusPct;

  factory RateCard.fromJson(Map<String, dynamic> json) => RateCard(
    kind: json['kind']?.toString() ?? 'FD',
    minTenureDays: (json['minTenureDays'] as num).toInt(),
    maxTenureDays: (json['maxTenureDays'] as num).toInt(),
    ratePct: (json['ratePct'] as num).toDouble(),
    seniorBonusPct: (json['seniorBonusPct'] as num).toDouble(),
  );
}
