class Deposit {
  const Deposit({
    required this.id,
    required this.kind,
    required this.principalPaise,
    required this.installmentPaise,
    required this.debitDate,
    required this.ratePct,
    required this.startDate,
    required this.maturityDate,
    required this.maturityPaise,
    required this.status,
    required this.daysToMaturity,
  });

  final String id;
  final String kind;
  final int principalPaise;
  final int? installmentPaise;
  final int? debitDate;
  final double ratePct;
  final DateTime startDate;
  final DateTime maturityDate;
  final int maturityPaise;
  final String status;
  final int daysToMaturity;

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
    id: json['id'] as String,
    kind: json['kind'] as String,
    principalPaise: (json['principalPaise'] as num).toInt(),
    installmentPaise: (json['installmentPaise'] as num?)?.toInt(),
    debitDate: (json['debitDate'] as num?)?.toInt(),
    ratePct: (json['ratePct'] as num).toDouble(),
    startDate: DateTime.parse(json['startDate'] as String),
    maturityDate: DateTime.parse(json['maturityDate'] as String),
    maturityPaise: (json['maturityPaise'] as num).toInt(),
    status: json['status'] as String,
    daysToMaturity: (json['daysToMaturity'] as num).toInt(),
  );
}
