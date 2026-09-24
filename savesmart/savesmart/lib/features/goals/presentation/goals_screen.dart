import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/mock_data.dart';
import '../../../core/utils/money.dart';
import '../../auth/state/session_provider.dart';
import '../data/goal_math.dart';
import '../widgets/goal_progress_ring.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int selectedTab = 0;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SaveSmart',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/nominees'),
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Nominee management',
          ),
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
    final totalSaved = session.goals.fold<int>(
      0,
      (sum, goal) => sum + goal.saved,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Good morning, ${session.user?.name ?? 'Aisha'}',
          style: const TextStyle(color: Color(0xFF5D6962)),
        ),
        const SizedBox(height: 22),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL SAVED',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupees(totalSaved),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '+12.4% this month',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
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
        ...session.goals.map(
          (goal) => _GoalTile(
            goal: goal,
            onTap: () => context.go('/home/goal/${goal.id}'),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => context.go('/home/new-goal'),
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
                onTap: () => context.go('/book-rd'),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 12),
        // Card(
        //   child: ListTile(
        //     leading: const Icon(Icons.people_alt_outlined),
        //     title: const Text('Nominee management'),
        //     subtitle: const Text('Manage nominees and share percentages'),
        //     trailing: const Icon(Icons.chevron_right),
        //     onTap: () => context.push('/nominees'),
        //   ),
        // ),
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
            Icon(
              _goalIcon(goal.iconKey),
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            GoalProgressRing(progress: goal.progress, size: 58),
            const SizedBox(width: 14),
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
              formatRupees(
                requiredMonthlySavingPaise(
                  targetPaise: goal.target,
                  savedPaise: goal.saved,
                  targetDate: goal.targetDate,
                ),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
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
