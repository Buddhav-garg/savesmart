import 'package:flutter/material.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({required this.goalId, super.key});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    final goal = mockGoals.firstWhere(
      (item) => item.id == goalId,
      orElse: () => mockGoals.first,
    );
    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: Color(goal.color),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${(goal.progress * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
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
        ],
      ),
    );
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
