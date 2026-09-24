import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';

class DepositBookingScreen extends StatefulWidget {
  const DepositBookingScreen({required this.kind, super.key});
  final String kind;

  bool get isFd => kind == 'FD';

  @override
  State<DepositBookingScreen> createState() => _DepositBookingScreenState();
}

class _DepositBookingScreenState extends State<DepositBookingScreen> {
  final session = AppSession.instance;
  final amountController = TextEditingController(text: '100000');
  final tenureController = TextEditingController(text: '12');
  final debitDateController = TextEditingController(text: '1');
  final nomineeNameController = TextEditingController();
  final nomineeRelationController = TextEditingController();
  final nomineeShareController = TextEditingController(text: '100');
  String tenureUnit = 'months';
  String payout = 'on_maturity';
  String renewal = 'none';
  String? errorMessage;
  bool submitting = false;
  String? bookingKey;

  @override
  void dispose() {
    amountController.dispose();
    tenureController.dispose();
    debitDateController.dispose();
    nomineeNameController.dispose();
    nomineeRelationController.dispose();
    nomineeShareController.dispose();
    super.dispose();
  }

  int? get tenureDays {
    final quantity = int.tryParse(tenureController.text.trim());
    if (quantity == null) return null;
    return switch (tenureUnit) {
      'days' => quantity,
      'months' => quantity * 30,
      'years' => quantity * 365,
      _ => null,
    };
  }

  int? get amountPaise => parseRupeesToPaise(amountController.text);

  List<String> get schedule {
    final months = (tenureDays ?? 0) ~/ 30;
    final installment = amountPaise ?? 0;
    return List.generate(months.clamp(0, 120), (index) {
      final month = index + 1;
      return 'Month $month: ${formatRupees(installment)}';
    });
  }

  Future<void> submit() async {
    final days = tenureDays;
    final amount = amountPaise;
    final debitDate = int.tryParse(debitDateController.text.trim());
    final nomineeName = nomineeNameController.text.trim();
    final nomineeShare = int.tryParse(nomineeShareController.text.trim());
    if (days == null || days < 7 || days > 3650) {
      setState(
        () => errorMessage = 'Tenure must be between 7 days and 10 years.',
      );
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => errorMessage = 'Enter a valid amount.');
      return;
    }
    if (widget.isFd && amount < 100000) {
      setState(() => errorMessage = 'Minimum FD amount is ₹1,000.');
      return;
    }
    if (!widget.isFd &&
        (debitDate == null || debitDate < 1 || debitDate > 28)) {
      setState(() => errorMessage = 'RD debit date must be between 1 and 28.');
      return;
    }
    if (widget.isFd && nomineeName.isNotEmpty && nomineeShare != 100) {
      setState(() => errorMessage = 'Nominee share must total 100%.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Review ${widget.isFd ? 'FD' : 'RD'} booking'),
        content: Text(
          '${widget.isFd ? 'Principal' : 'Monthly instalment'}: ${formatRupees(amount)}\nTenure: ${tenureController.text} $tenureUnit\n${widget.isFd ? 'Payout: $payout\nRenewal: $renewal' : 'Debit date: $debitDate'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    bookingKey ??= '${DateTime.now().microsecondsSinceEpoch}-${widget.kind}';
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await session.bookDeposit(
        kind: widget.kind,
        tenureDays: days,
        principalPaise: widget.isFd ? amount : null,
        installmentPaise: widget.isFd ? null : amount,
        debitDate: widget.isFd ? null : debitDate,
        payout: payout,
        renewal: renewal,
        nomineeName: widget.isFd && nomineeName.isNotEmpty ? nomineeName : null,
        nomineeRelation: widget.isFd && nomineeName.isNotEmpty
            ? nomineeRelationController.text.trim()
            : null,
        nomineeSharePct: widget.isFd && nomineeName.isNotEmpty
            ? nomineeShare
            : null,
        idempotencyKey: bookingKey!,
      );
      bookingKey = null;
      if (mounted) context.go('/deposits');
    } catch (error) {
      if (mounted) await presentBankError(context, error);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.isFd ? 'Book an FD' : 'Book an RD')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.isFd ? 'Lock in a fixed return' : 'Build savings every month',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isFd
              ? 'Choose your principal, payout, nominee and renewal instruction.'
              : 'Choose your instalment, tenure and debit date.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.isFd ? 'Principal amount' : 'Monthly instalment',
            prefixText: '₹ ',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tenureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tenure'),
                onChanged: (_) => setState(() {}),
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
                onChanged: (value) => setState(() => tenureUnit = value!),
              ),
            ),
          ],
        ),
        if (!widget.isFd) ...[
          const SizedBox(height: 14),
          TextField(
            controller: debitDateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Debit date',
              hintText: '1 to 28',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Instalment schedule',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (schedule.isEmpty)
            const Text('Enter a valid tenure to preview the schedule.')
          else
            ...schedule
                .take(12)
                .map((item) => ListTile(dense: true, title: Text(item))),
        ],
        if (widget.isFd) ...[
          const SizedBox(height: 20),
          Text(
            'Payout and renewal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: payout,
            decoration: const InputDecoration(labelText: 'Payout'),
            items: const [
              DropdownMenuItem(
                value: 'on_maturity',
                child: Text('At maturity'),
              ),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
            ],
            onChanged: (value) => setState(() => payout = value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: renewal,
            decoration: const InputDecoration(labelText: 'Renewal'),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Do not renew')),
              DropdownMenuItem(
                value: 'principal',
                child: Text('Renew principal'),
              ),
              DropdownMenuItem(
                value: 'principal_interest',
                child: Text('Renew principal and interest'),
              ),
            ],
            onChanged: (value) => setState(() => renewal = value!),
          ),
          const SizedBox(height: 20),
          Text(
            'Nominee (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/nominees'),
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text('Manage saved nominees'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nomineeNameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomineeRelationController,
            decoration: const InputDecoration(labelText: 'Relation'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nomineeShareController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Share',
              suffixText: '%',
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (errorMessage != null) ...[
          Text(
            errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: submitting ? null : submit,
            child: Text(submitting ? 'Booking...' : 'Review and confirm'),
          ),
        ),
      ],
    ),
  );
}
