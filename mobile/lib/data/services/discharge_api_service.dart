// This is the ONLY file that should talk to the backend server directly.
// Every screen that needs to call the backend should go through the two
// methods below, instead of writing its own network code.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/models/discharge_request.dart';
import '../../core/models/session.dart';

class DischargeApi {
  // -------------------------------------------------------------
  // CHANGE THIS depending on how you're running the app:
  //
  // - Android emulator  -> keep it as 10.0.2.2
  // - Physical Android phone (same wifi as your computer)
  //      -> replace with your computer's actual network address,
  //         e.g. "http://192.168.1.23:3000"
  //         (find it by running `ipconfig` in a terminal on your PC
  //         and looking for "IPv4 Address")
  // -------------------------------------------------------------
  static const String baseUrl = "http://10.0.2.2:3000";

  /// Sends the discharge text to the backend and returns a filled-in
  /// DischargeSession (simplified instructions + teach-back questions).
  /// Throws an Exception if anything goes wrong — the calling screen
  /// should catch this and show a normal error message to the user.
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
        "Could not process discharge instructions (status ${response.statusCode}). "
        "Try again, or use the backup text if this keeps failing.",
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final questions = (data['teachBackQuestions'] as List)
        .map((q) => TeachBackQuestion(
              id: q['id'] as String,
              question: q['question'] as String,
            ))
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

  /// Grades a single answer to a single question, and fills in the
  /// answer/correct/score/feedback fields directly on that question object.
  /// Call this once per question, not once for the whole session.
  static Future<void> gradeAnswer({
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
        "Could not grade this answer (status ${response.statusCode}).",
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Fill the answer/grade straight onto the question object that was
    // passed in, so the calling screen doesn't have to do this itself.
    question.patientAnswer = patientAnswer;
    question.correct = data['correct'] as bool;
    question.score = data['score'] as int;
    question.feedback = data['feedback'] as String;
  }
}