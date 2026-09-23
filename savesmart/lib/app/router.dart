import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/deposits/presentation/deposits_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/goals/presentation/new_goal_screen.dart';
import '../features/goals/presentation/auto_save_screen.dart';
import '../features/deposits/presentation/fd_calculator_screen.dart';
import '../features/deposits/presentation/rd_screen.dart';
import '../features/deposits/presentation/deposit_booking_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const GoalsScreen(),
      routes: [
        GoRoute(
          path: 'new-goal',
          builder: (context, state) => const NewGoalScreen(),
        ),
        GoRoute(
          path: 'goal/:id',
          builder: (context, state) =>
              GoalDetailScreen(goalId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'auto-save',
              builder: (context, state) =>
                  AutoSaveScreen(goalId: state.pathParameters['id']!),
            ),
          ],
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
    GoRoute(
      path: '/book-fd',
      builder: (context, state) => const DepositBookingScreen(kind: 'FD'),
    ),
    GoRoute(
      path: '/book-rd',
      builder: (context, state) => const DepositBookingScreen(kind: 'RD'),
    ),
  ],
);
