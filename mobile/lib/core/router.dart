import 'package:go_router/go_router.dart';
import '../core/models/process_discharge_response.dart';
import '../core/models/discharge_request.dart';
import '../core/models/teachback_session.dart';
import '../features/auth/auth_screen.dart';
import '../features/scan/scan_screen.dart';
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
  path: '/teachback',
  builder: (context, state) {
    final data = state.extra as Map<String, dynamic>;

    final request = data['request'] as DischargeRequest;
    final processResponse =
        data['processResponse'] as ProcessDischargeResponse;

    return TeachbackScreen(
      dischargeRequest: request,
      processResponse: processResponse,
    );
  },
),

    GoRoute(
  path: '/results',
  builder: (context, state) {
    final session = state.extra as TeachbackSession;

    return ResultsScreen(
      teachbackSession: session,
    );
  },
),
  ],
);