class DischargeRequest {
  final String patientId;
  final String dischargeText;

  const DischargeRequest({
    required this.patientId,
    required this.dischargeText,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'dischargeText': dischargeText,
    };
  }
}