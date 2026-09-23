import 'package:flutter/material.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';

class DepositsScreen extends StatefulWidget {
  const DepositsScreen({super.key});

  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  String selectedKind = 'ALL';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Deposits')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Your portfolio',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: ['ALL', 'FIXED DEPOSIT', 'RECURRING DEPOSIT']
              .map(
                (kind) => ChoiceChip(
                  label: Text(
                    kind == 'ALL'
                        ? 'All'
                        : kind == 'FIXED DEPOSIT'
                        ? 'FD'
                        : 'RD',
                  ),
                  selected: selectedKind == kind,
                  onSelected: (_) => setState(() => selectedKind = kind),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        ...mockDeposits
            .where(
              (deposit) =>
                  selectedKind == 'ALL' || deposit.kind == selectedKind,
            )
            .map(
              (deposit) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            deposit.kind,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        deposit.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            deposit.kind == 'RECURRING DEPOSIT'
                                ? '${formatRupees(deposit.installmentPaise)} / month'
                                : formatRupees(deposit.amountPaise),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            deposit.rate,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        deposit.maturity,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Book another deposit'),
        ),
      ],
    ),
  );
}
