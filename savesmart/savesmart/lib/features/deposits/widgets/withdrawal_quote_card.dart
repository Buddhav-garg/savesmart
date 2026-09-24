import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../domain/withdrawal_quote.dart';

class WithdrawalQuoteCard extends StatelessWidget {
  const WithdrawalQuoteCard({
    required this.quote,
    required this.onConfirm,
    super.key,
  });
  final WithdrawalQuote quote;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premature withdrawal quote',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'You receive ${formatRupees(quote.payablePaise)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text('Penalty: ${formatRupees(quote.penaltyPaise)}'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onConfirm,
              child: const Text('Confirm withdrawal'),
            ),
          ),
        ],
      ),
    ),
  );
}
