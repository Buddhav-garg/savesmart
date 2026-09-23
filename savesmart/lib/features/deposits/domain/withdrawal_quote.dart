class WithdrawalQuote {
  const WithdrawalQuote({
    required this.quoteId,
    required this.depositId,
    required this.payablePaise,
    required this.penaltyPaise,
    required this.expiresAt,
  });

  final String quoteId;
  final String depositId;
  final int payablePaise;
  final int penaltyPaise;
  final DateTime expiresAt;

  factory WithdrawalQuote.fromJson(Map<String, dynamic> json) =>
      WithdrawalQuote(
        quoteId: json['quoteId']?.toString() ?? '',
        depositId: json['depositId']?.toString() ?? '',
        payablePaise: (json['payablePaise'] as num?)?.toInt() ?? 0,
        penaltyPaise: (json['penaltyPaise'] as num?)?.toInt() ?? 0,
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
