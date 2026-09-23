import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';

class RdScreen extends StatelessWidget {
  const RdScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Start an RD')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Build it monthly',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Small, regular deposits can make a meaningful difference.'),
        const SizedBox(height: 28),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Monthly instalment',
            prefixText: '₹  ',
          ),
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Tenure',
            suffixText: 'months',
          ),
        ),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Debit date',
            hintText: 'Choose a date between 1 and 28',
          ),
        ),
        const SizedBox(height: 28),
        Card(
          color: const Color(0xFFFFD7A8),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR PLAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${formatRupees(500000)} × 24 months',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text('Estimated maturity: ${formatRupees(12870000)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: FilledButton(onPressed: () {}, child: const Text('Review RD')),
        ),
      ],
    ),
  );
}
