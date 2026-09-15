import 'package:go_router/go_router.dart';

import '../core/models/session.dart';
import '../features/auth/auth_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/teachback/teachback_screen.dart';
import '../features/results/results_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),

    GoRoute(
      path: '/summary',
      builder: (context, state) {
        final session = state.extra as DischargeSession;

        return SummaryScreen(
          session: session,
        );
      },
    ),

    GoRoute(
      path: '/teachback',
      builder: (context, state) {
        final session = state.extra as DischargeSession;

        return TeachbackScreen(
          session: session,
        );
      },
    ),

    GoRoute(
      path: '/results',
      builder: (context, state) {
        final session = state.extra as DischargeSession;

        return ResultsScreen(
          session: session,
        );
      },
    ),
  ],
);