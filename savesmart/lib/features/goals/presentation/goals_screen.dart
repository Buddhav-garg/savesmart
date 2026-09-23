import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SaveSmart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [_goals(context), _snapshot(context)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) => setState(() => selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Snapshot',
          ),
        ],
      ),
    );
  }

  Widget _goals(BuildContext context) {
    final totalSaved = mockGoals.fold<int>(0, (sum, goal) => sum + goal.saved);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const Text(
          'Good morning, Aisha',
          style: TextStyle(color: Color(0xFF5D6962)),
        ),
        const SizedBox(height: 6),
        Text(
          'Your money has\na direction.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 22),
        Card(
          color: const Color(0xFF17221D),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL SAVED',
                  style: TextStyle(
                    color: Color(0xFFB9E8D0),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupees(totalSaved),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFFB9E8D0), size: 18),
                    SizedBox(width: 6),
                    Text(
                      '+12.4% this month',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your goals', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 10),
        ...mockGoals.map(
          (goal) => _GoalTile(
            goal: goal,
            onTap: () => context.go('/home/goal/${goal.id}'),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Create a new goal'),
        ),
        const SizedBox(height: 28),
        Text(
          'Grow your savings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.calculate_outlined,
                title: 'FD calculator',
                onTap: () => context.go('/fd-calculator'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_month_outlined,
                title: 'Start an RD',
                onTap: () => context.go('/rd'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _snapshot(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: () => context.go('/deposits'),
      icon: const Icon(Icons.account_balance_wallet_outlined),
      label: const Text('View your deposits'),
    ),
  );
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onTap});
  final MockGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatRupees(goal.saved)} of ${formatRupees(goal.target)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(goal.progress * 100).round()}%',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 22),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ),
  );
}
