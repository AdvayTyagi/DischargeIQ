import 'discharge_request.dart';
import 'process_discharge_response.dart';
import 'grade_answer_response.dart';

class TeachbackSession {
  final DischargeRequest dischargeRequest;
  final ProcessDischargeResponse processResponse;
  final TeachBackQuestion question;
  final String answer;
  final GradeAnswerResponse gradeResponse;

  const TeachbackSession({
    required this.dischargeRequest,
    required this.processResponse,
    required this.question,
    required this.answer,
    required this.gradeResponse,
  });
}