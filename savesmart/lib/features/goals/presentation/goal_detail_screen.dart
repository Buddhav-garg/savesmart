import 'package:flutter/material.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';
import '../data/goal_math.dart';
import '../widgets/goal_progress_ring.dart';
import '../widgets/milestone_celebration.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({required this.goalId, super.key});
  final String goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final session = AppSession.instance;
  final amountController = TextEditingController();
  String? contributionKey;
  String? errorMessage;
  int? reachedMilestone;
  bool isContributing = false;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    amountController.dispose();
    super.dispose();
  }

  void _onSessionChanged() => setState(() {});

  Future<void> _addMoney(MockGoal goal) async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final controller = TextEditingController();
        String? validationMessage;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add money to ${goal.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    errorText: validationMessage,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      final paise = parseRupeesToPaise(controller.text);
                      if (paise == null || paise <= 0) {
                        setSheetState(
                          () => validationMessage = 'Enter a valid amount.',
                        );
                        return;
                      }
                      Navigator.of(sheetContext).pop(paise);
                    },
                    child: const Text('Confirm transfer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (amount == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review transfer'),
        content: Text(
          'Transfer ${formatRupees(amount)} from your savings account to ${goal.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Transfer money'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    contributionKey ??= '${DateTime.now().microsecondsSinceEpoch}-${goal.id}';
    final previousProgress = goal.progress;
    setState(() {
      errorMessage = null;
      isContributing = true;
    });
    try {
      final updated = await session.contributeToGoal(
        goalId: goal.id,
        amountPaise: amount,
        idempotencyKey: contributionKey!,
      );
      final newProgress = updated.progress;
      const milestones = [25, 50, 75, 100];
      final milestone = milestones
          .where(
            (value) =>
                previousProgress * 100 < value && newProgress * 100 >= value,
          )
          .fold<int?>(null, (highest, value) => value);
      setState(() {
        reachedMilestone = milestone;
        contributionKey = null;
      });
    } catch (error) {
      setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => isContributing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = session.goals.firstWhere(
      (item) => item.id == widget.goalId,
      orElse: () => session.goals.first,
    );
    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: reachedMilestone == null
                ? const SizedBox(key: ValueKey('no-milestone'))
                : MilestoneCelebration(
                    key: ValueKey(reachedMilestone),
                    milestone: reachedMilestone!,
                  ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: errorMessage == null
                ? const SizedBox(key: ValueKey('no-error'))
                : Text(
                    errorMessage!,
                    key: ValueKey(errorMessage),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(_goalIcon(goal.iconKey), size: 32),
                  const SizedBox(height: 12),
                  GoalProgressRing(progress: goal.progress, size: 110),
                  const Text('of your goal completed'),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Keep the momentum',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'You are building a habit that makes the future feel closer.',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: isContributing ? null : () => _addMoney(goal),
              icon: const Icon(Icons.add),
              label: Text(isContributing ? 'Transferring...' : 'Add money'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.autorenew),
            label: const Text('Set up auto-save'),
          ),
          const SizedBox(height: 28),
          Text('Goal details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(label: 'Target date', value: goal.due),
          _InfoRow(label: 'Saved so far', value: formatRupees(goal.saved)),
          _InfoRow(
            label: 'Still needed',
            value: formatRupees(goal.target - goal.saved),
          ),
          _InfoRow(
            label: 'Required monthly saving',
            value: formatRupees(
              requiredMonthlySavingPaise(
                targetPaise: goal.target,
                savedPaise: goal.saved,
                targetDate: goal.targetDate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _goalIcon(String key) {
  switch (key) {
    case 'home':
      return Icons.home_outlined;
    case 'safety':
      return Icons.shield_outlined;
    case 'education':
      return Icons.school_outlined;
    case 'travel':
    default:
      return Icons.flight_outlined;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
