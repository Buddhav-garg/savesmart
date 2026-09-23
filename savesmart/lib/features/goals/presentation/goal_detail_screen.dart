import 'package:flutter/material.dart';

import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';
import '../data/goal_math.dart';
import '../widgets/goal_progress_ring.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({required this.goalId, super.key});
  final String goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final session = AppSession.instance;

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
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add money'),
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
