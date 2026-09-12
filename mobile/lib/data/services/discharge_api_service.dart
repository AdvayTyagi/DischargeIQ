import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/models/discharge_request.dart';
import '../../core/models/grade_answer_response.dart';
import '../../core/models/process_discharge_response.dart';

class DischargeApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  final http.Client client;

  DischargeApiService({
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<ProcessDischargeResponse> processDischarge(
    DischargeRequest request,
  ) async {
    final response = await client
        .post(
          Uri.parse('$baseUrl/process-discharge'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Process discharge failed: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return ProcessDischargeResponse.fromJson(json);
  }

  Future<GradeAnswerResponse> gradeAnswer({
    required DischargeRequest request,
    required String question,
    required String patientAnswer,
  }) async {
    final body = {
      'patientId': request.patientId,
      'preferredLanguage': request.preferredLanguage,
      'dischargeText': request.dischargeText,
      'question': question,
      'patientAnswer': patientAnswer,
    };

    final response = await client
        .post(
          Uri.parse('$baseUrl/grade-answer'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Grade answer failed: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return GradeAnswerResponse.fromJson(json);
  }
}