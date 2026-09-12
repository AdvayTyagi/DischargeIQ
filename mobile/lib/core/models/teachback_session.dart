import 'discharge_request.dart';

class TeachbackSession {
  final DischargeRequest dischargeRequest;
  final String answer;

  const TeachbackSession({
    required this.dischargeRequest,
    required this.answer,
  });
}