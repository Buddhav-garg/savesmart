import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';

class FdCalculatorScreen extends StatefulWidget {
  const FdCalculatorScreen({super.key});
  @override
  State<FdCalculatorScreen> createState() => _FdCalculatorScreenState();
}

class _FdCalculatorScreenState extends State<FdCalculatorScreen> {
  int amountPaise = 10000000;
  @override
  Widget build(BuildContext context) {
    final maturityPaise = (amountPaise * 1.0725).round();
    return Scaffold(
      appBar: AppBar(title: const Text('FD calculator')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'See your money grow',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('A simple estimate for your fixed deposit.'),
          const SizedBox(height: 30),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESTIMATED MATURITY',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatRupees(maturityPaise),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '7.25% p.a. · 12 months',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Deposit amount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            formatRupees(amountPaise),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: amountPaise.toDouble(),
            min: 1000000,
            max: 50000000,
            divisions: 49,
            label: formatRupees(amountPaise),
            onChanged: (value) => setState(() => amountPaise = value.round()),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () {},
              child: const Text('Book this FD'),
            ),
          ),
        ],
      ),
    );
  }
}
