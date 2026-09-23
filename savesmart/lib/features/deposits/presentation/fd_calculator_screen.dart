import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/money.dart';
import '../data/deposit_math.dart';
import '../data/rate_repository.dart';
import '../domain/rate_card.dart';

class FdCalculatorScreen extends StatefulWidget {
  const FdCalculatorScreen({super.key});
  @override
  State<FdCalculatorScreen> createState() => _FdCalculatorScreenState();
}

class _FdCalculatorScreenState extends State<FdCalculatorScreen> {
  final amountController = TextEditingController(text: '100000');
  final tenureQuantityController = TextEditingController(text: '12');
  final rateRepository = RateRepository(ApiClient());
  Timer? rateDebounce;
  int principalPaise = 10000000;
  int tenureDays = 365;
  String tenureUnit = 'months';
  String payout = 'on_maturity';
  RateCard? rateCard;
  String? errorMessage;
  bool loadingRate = true;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  @override
  void dispose() {
    rateDebounce?.cancel();
    amountController.dispose();
    tenureQuantityController.dispose();
    super.dispose();
  }

  void _scheduleRateLookup(int days) {
    rateDebounce?.cancel();
    rateDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _loadRate(days),
    );
  }

  Future<void> _loadRate([int? days]) async {
    final requestedDays = days ?? tenureDays;
    setState(() {
      loadingRate = true;
      errorMessage = null;
    });
    try {
      final result = await rateRepository.getFdRate(requestedDays);
      if (!mounted || requestedDays != tenureDays) return;
      setState(() => rateCard = result);
    } catch (error) {
      if (mounted && requestedDays == tenureDays) {
        setState(() => errorMessage = error.toString());
      }
    } finally {
      if (mounted && requestedDays == tenureDays) {
        setState(() => loadingRate = false);
      }
    }
  }

  void _setPrincipal(String value) {
    final parsed = parseRupeesToPaise(value);
    if (parsed != null && parsed > 0) setState(() => principalPaise = parsed);
  }

  void _setTenure({String? unit, String? quantity}) {
    final selectedUnit = unit ?? tenureUnit;
    final value = int.tryParse(
      quantity ?? tenureQuantityController.text.trim(),
    );
    if (value == null) return;

    final days = switch (selectedUnit) {
      'days' => value,
      'months' => value * 30,
      'years' => value * 365,
      _ => 365,
    };
    if (days < 7 || days > 3650) {
      setState(
        () => errorMessage = 'Tenure must be between 7 days and 10 years.',
      );
      return;
    }
    setState(() {
      tenureUnit = selectedUnit;
      tenureDays = days;
      errorMessage = null;
    });
    _scheduleRateLookup(days);
  }

  String get tenureLabel {
    if (tenureDays >= 365 && tenureDays % 365 == 0) {
      final years = tenureDays ~/ 365;
      return '$years year${years == 1 ? '' : 's'}';
    }
    return '$tenureDays days';
  }

  @override
  Widget build(BuildContext context) {
    final rate = rateCard?.ratePct;
    final maturityPaise = rate == null
        ? null
        : DepositMath.fdMaturity(principalPaise, rate, tenureDays);
    final interestPaise = maturityPaise == null
        ? null
        : maturityPaise - principalPaise;
    final yield = maturityPaise == null
        ? null
        : DepositMath.effectiveYieldPct(
            principalPaise: principalPaise,
            maturityPaise: maturityPaise,
            tenureDays: tenureDays,
          );
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
          const Text('Rates are fetched from the current FD rate card.'),
          const SizedBox(height: 24),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Principal',
              prefixText: '₹ ',
            ),
            onChanged: _setPrincipal,
          ),
          const SizedBox(height: 24),
          Text('Tenure', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: tenureQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  onChanged: (value) => _setTenure(quantity: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: tenureUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(value: 'days', child: Text('Days')),
                    DropdownMenuItem(value: 'months', child: Text('Months')),
                    DropdownMenuItem(value: 'years', child: Text('Years')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _setTenure(unit: value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Equivalent tenure: $tenureLabel'),
          const SizedBox(height: 12),
          Text('Payout type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'on_maturity', label: Text('At maturity')),
              ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ButtonSegment(value: 'quarterly', label: Text('Quarterly')),
            ],
            selected: {payout},
            onSelectionChanged: (value) => setState(() => payout = value.first),
          ),
          const SizedBox(height: 24),
          if (loadingRate)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
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
                      formatRupees(maturityPaise!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResultRow(
                      label: 'Interest earned',
                      value: formatRupees(interestPaise!),
                    ),
                    _ResultRow(
                      label: 'Rate',
                      value: '${rate!.toStringAsFixed(2)}% p.a.',
                    ),
                    _ResultRow(
                      label: 'Effective yield',
                      value: '${yield!.toStringAsFixed(2)}% p.a.',
                    ),
                    _ResultRow(
                      label: 'Payout',
                      value: payout == 'on_maturity'
                          ? 'At maturity'
                          : '${payout[0].toUpperCase()}${payout.substring(1)}',
                    ),
                  ],
                ),
              ),
            ),
          if (!loadingRate && errorMessage == null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => context.go('/book-fd'),
                child: const Text('Book this FD'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
