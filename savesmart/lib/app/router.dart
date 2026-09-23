import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/deposits/presentation/deposits_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/deposits/presentation/fd_calculator_screen.dart';
import '../features/deposits/presentation/rd_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const GoalsScreen(),
      routes: [
        GoRoute(
          path: 'goal/:id',
          builder: (context, state) =>
              GoalDetailScreen(goalId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/deposits',
      builder: (context, state) => const DepositsScreen(),
    ),
    GoRoute(
      path: '/fd-calculator',
      builder: (context, state) => const FdCalculatorScreen(),
    ),
    GoRoute(path: '/rd', builder: (context, state) => const RdScreen()),
  ],
);
