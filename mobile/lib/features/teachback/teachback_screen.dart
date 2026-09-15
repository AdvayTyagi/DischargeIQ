import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/discharge_api_service.dart';
import '../../core/models/discharge_request.dart';
import '../../core/models/process_discharge_response.dart';
import '../../core/models/teachback_session.dart';


class TeachbackScreen extends StatefulWidget {
  final DischargeRequest dischargeRequest;
  final ProcessDischargeResponse processResponse;

  const TeachbackScreen({
    super.key,
    required this.dischargeRequest,
    required this.processResponse,
  });

  @override
  State<TeachbackScreen> createState() => _TeachbackScreenState();
}

class _TeachbackScreenState extends State<TeachbackScreen> {
  final TextEditingController _answerController =
      TextEditingController();

bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
  final answer = _answerController.text.trim();

  if (answer.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your answer.'),
      ),
    );
    return;
  }

  final question =
      widget.processResponse.teachBackQuestions.first;

  setState(() {
    _isSubmitting = true;
  });

  try {
    final apiService = DischargeApiService();

    final gradeResponse = await apiService.gradeAnswer(
      request: widget.dischargeRequest,
      question: question.question,
      patientAnswer: answer,
    );

    if (!mounted) return;

    final session = TeachbackSession(
      dischargeRequest: widget.dischargeRequest,
      processResponse: widget.processResponse,
      question: question,
      answer: answer,
      gradeResponse: gradeResponse,
    );

    context.push(
      '/results',
      extra: session,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to grade answer: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final question =
        widget.processResponse.teachBackQuestions.first.question;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teach-back'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teach-back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please answer the following question in your own words.',
            ),
            const SizedBox(height: 32),
            Text(
              question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAnswer,
                

child: Text(
  _isSubmitting ? 'Grading...' : 'Submit Answer',
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}