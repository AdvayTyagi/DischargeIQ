class TeachBackQuestion {
  final String id;
  final String question;

  const TeachBackQuestion({
    required this.id,
    required this.question,
  });

  factory TeachBackQuestion.fromJson(Map<String, dynamic> json) {
    return TeachBackQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
    );
  }
}

class ProcessDischargeResponse {
  final String patientId;
  final String preferredLanguage;
  final List<String> simplifiedInstructions;
  final List<TeachBackQuestion> teachBackQuestions;

  const ProcessDischargeResponse({
    required this.patientId,
    required this.preferredLanguage,
    required this.simplifiedInstructions,
    required this.teachBackQuestions,
  });

  factory ProcessDischargeResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProcessDischargeResponse(
      patientId: json['patientId'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      simplifiedInstructions:
          List<String>.from(json['simplifiedInstructions'] as List),
      teachBackQuestions:
          (json['teachBackQuestions'] as List)
              .map(
                (item) => TeachBackQuestion.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}