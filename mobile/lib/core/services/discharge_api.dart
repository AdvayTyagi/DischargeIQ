// This is the ONLY file that should talk to the backend server directly.
// Every screen that needs to call the backend should go through the two
// methods below, instead of writing its own network code.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/models/discharge_request.dart';
import '../../core/models/grade_answer_response.dart';
import '../../core/models/session.dart';

class DischargeApi {
  // -------------------------------------------------------------
  // Production backend deployed on Render.
  // -------------------------------------------------------------
  static const String baseUrl =
      'https://dischargeiq-backend.onrender.com';

  /// Sends the discharge text to the backend and returns a filled-in
  /// DischargeSession (simplified instructions + teach-back questions).
  static Future<DischargeSession> processDischarge(
    DischargeRequest request,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/process-discharge"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Could not process discharge instructions "
        "(status ${response.statusCode}). "
        "Try again, or use the backup text if this keeps failing.",
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final questions = (data['teachBackQuestions'] as List)
        .map(
          (q) => TeachBackQuestion(
            id: q['id'] as String,
            question: q['question'] as String,
          ),
        )
        .toList();

    return DischargeSession(
      patientId: data['patientId'] as String,
      preferredLanguage: data['preferredLanguage'] as String,
      dischargeText: request.dischargeText,
      simplifiedInstructions:
          List<String>.from(data['simplifiedInstructions'] as List),
      teachBackQuestions: questions,
    );
  }

  /// Grades a single answer to a single question.
  ///
  /// The backend returns:
  /// - correct
  /// - score
  /// - feedback
  /// - correctAnswer
  ///
  /// Those values are copied directly onto the question so the Results
  /// screen can display them.
  static Future<GradeAnswerResponse> gradeAnswer({
    required DischargeSession session,
    required TeachBackQuestion question,
    required String patientAnswer,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/grade-answer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "patientId": session.patientId,
        "preferredLanguage": session.preferredLanguage,
        "dischargeText": session.dischargeText,
        "question": question.question,
        "patientAnswer": patientAnswer,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to grade answer: "
        "${response.statusCode} ${response.body}",
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final gradeResponse = GradeAnswerResponse.fromJson(data);

    // Save the grading result directly onto this question.
    question.patientAnswer = patientAnswer;
    question.correct = gradeResponse.correct;
    question.score = gradeResponse.score;
    question.feedback = gradeResponse.feedback;
    question.correctAnswer = gradeResponse.correctAnswer;
    question.attempts++;

    return gradeResponse;
  }
}