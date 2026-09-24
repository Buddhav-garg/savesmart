import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/biometric_service.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';
import '../domain/deposit.dart';
import '../domain/withdrawal_quote.dart';
import '../widgets/days_to_maturity_bar.dart';
import '../widgets/withdrawal_quote_card.dart';

class DepositsScreen extends StatefulWidget {
  const DepositsScreen({super.key});

  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  final session = AppSession.instance;
  final biometricService = BiometricService();
  String selectedKind = 'ALL';
  String sort = 'maturity';
  String? errorMessage;
  String? loadingDepositId;
  WithdrawalQuote? quote;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() => setState(() {});

  List<Deposit> get visibleDeposits {
    final deposits = session.portfolioDeposits
        .where(
          (deposit) => selectedKind == 'ALL' || deposit.kind == selectedKind,
        )
        .toList();
    deposits.sort(
      (a, b) => sort == 'maturity'
          ? a.maturityDate.compareTo(b.maturityDate)
          : b.principalPaise.compareTo(a.principalPaise),
    );
    return deposits;
  }

  Future<void> _getQuote(Deposit deposit) async {
    setState(() {
      loadingDepositId = deposit.id;
      errorMessage = null;
    });
    try {
      final result = await session.requestWithdrawalQuote(deposit.id);
      if (mounted) setState(() => quote = result);
      if (mounted) await _showQuote(deposit, result);
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loadingDepositId = null);
    }
  }

  Future<void> _showQuote(
    Deposit deposit,
    WithdrawalQuote withdrawalQuote,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review withdrawal'),
        content: WithdrawalQuoteCard(
          quote: withdrawalQuote,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep deposit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final authenticated = await biometricService.confirmWithdrawal();
    if (!authenticated) {
      setState(
        () => errorMessage = 'Biometric confirmation was not completed.',
      );
      return;
    }
    try {
      setState(() => loadingDepositId = deposit.id);
      await session.withdrawDeposit(
        depositId: deposit.id,
        quoteId: withdrawalQuote.quoteId,
      );
      if (mounted) {
        setState(() {
          quote = null;
          errorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loadingDepositId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposits = visibleDeposits;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposits'),
        actions: [
          IconButton(
            onPressed: () => context.push('/nominees'),
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Manage nominees',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your portfolio',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['ALL', 'FD', 'RD']
                .map(
                  (kind) => ChoiceChip(
                    label: Text(kind == 'ALL' ? 'All' : kind),
                    selected: selectedKind == kind,
                    onSelected: (_) => setState(() => selectedKind = kind),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'maturity', label: Text('Maturity')),
              ButtonSegment(value: 'principal', label: Text('Principal')),
            ],
            selected: {sort},
            onSelectionChanged: (value) => setState(() => sort = value.first),
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (deposits.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No deposits found.'),
              ),
            ),
          ...deposits.map(
            (deposit) => _DepositPortfolioCard(
              deposit: deposit,
              busy: loadingDepositId == deposit.id,
              onWithdraw: () => _getQuote(deposit),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositPortfolioCard extends StatelessWidget {
  const _DepositPortfolioCard({
    required this.deposit,
    required this.busy,
    required this.onWithdraw,
  });
  final Deposit deposit;
  final bool busy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(deposit.kind, style: Theme.of(context).textTheme.labelLarge),
              Text(
                '${deposit.ratePct.toStringAsFixed(2)}% p.a.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatRupees(deposit.principalPaise),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Matures ${deposit.maturityDate.day}/${deposit.maturityDate.month}/${deposit.maturityDate.year}',
          ),
          const SizedBox(height: 14),
          DaysToMaturityBar(days: deposit.daysToMaturity),
          if (deposit.status == 'active') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: busy ? null : onWithdraw,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_open_outlined),
                label: const Text('Withdrawal quote'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
