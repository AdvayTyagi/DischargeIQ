// This file describes what one "session" looks like while the app is
// running. Nothing here is saved anywhere permanent — it just lives in
// memory for as long as the app is open, which is exactly what the team
// decided on (Option B, no Firestore).
//
// This matches docs/CONTRACT.MD exactly. If the backend contract ever
// changes, this file needs to change too.

/// One teach-back question, plus whatever answer/grade it has so far
/// (starts out empty, gets filled in as the patient answers).
class TeachBackQuestion {
  final String id;
  final String question;

  // These three start out null and get filled in after the patient
  // answers this specific question and we call /grade-answer for it.
  String? patientAnswer;
  bool? correct;
  int? score; // will be 0 or 1 once graded
  String? feedback;

  // How many times this exact question has been asked so far.
  // Starts at 0, goes up by 1 every time it's graded (right or wrong).
  int attempts = 0;

  TeachBackQuestion({
    required this.id,
    required this.question,
  });

  bool get isAnswered => patientAnswer != null;
  bool get isGraded => correct != null;
}

/// One full patient session: the original text, the simplified version,
/// and every teach-back question that goes with it.
class DischargeSession {
  final String patientId;
  final String preferredLanguage;
  final String dischargeText;

  // These two get filled in once /process-discharge responds.
  List<String> simplifiedInstructions;
  List<TeachBackQuestion> teachBackQuestions;

  DischargeSession({
    required this.patientId,
    required this.preferredLanguage,
    required this.dischargeText,
    this.simplifiedInstructions = const [],
    this.teachBackQuestions = const [],
  });

  /// True once every question in this session has been answered and graded.
  bool get isComplete =>
      teachBackQuestions.isNotEmpty &&
      teachBackQuestions.every((q) => q.isGraded);

  /// How many questions the patient got right, out of how many total.
  /// Only counts questions that have actually been graded so far.
  (int correctCount, int totalGraded) get scoreSoFar {
    final graded = teachBackQuestions.where((q) => q.isGraded);
    final correctCount = graded.where((q) => q.correct == true).length;
    return (correctCount, graded.length);
  }
}