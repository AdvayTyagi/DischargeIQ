class DischargeRequest {
  final String patientId;
  final String preferredLanguage;
  final String dischargeText;

  const DischargeRequest({
    required this.patientId,
    required this.preferredLanguage,
    required this.dischargeText,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'preferredLanguage': preferredLanguage,
      'dischargeText': dischargeText,
    };
  }
}