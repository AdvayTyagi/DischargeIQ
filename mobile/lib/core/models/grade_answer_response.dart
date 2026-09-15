class GradeAnswerResponse {
  final String patientId;
  final bool correct;
  final int score;
  final String feedback;
  final String? correctAnswer;

  GradeAnswerResponse({
    required this.patientId,
    required this.correct,
    required this.score,
    required this.feedback,
    this.correctAnswer,
  });

  factory GradeAnswerResponse.fromJson(Map<String, dynamic> json) {
    return GradeAnswerResponse(
      patientId: json['patientId'] as String,
      correct: json['correct'] as bool,
      score: json['score'] as int,
      feedback: json['feedback'] as String,
      correctAnswer: json['correctAnswer'] as String?,
    );
  }
}