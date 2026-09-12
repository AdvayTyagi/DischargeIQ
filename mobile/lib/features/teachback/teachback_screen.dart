import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/discharge_request.dart';
import '../../core/models/teachback_session.dart';

class TeachbackScreen extends StatefulWidget {
  final DischargeRequest dischargeRequest;

  const TeachbackScreen({
    super.key,
    required this.dischargeRequest,
  });

  @override
  State<TeachbackScreen> createState() => _TeachbackScreenState();
}

class _TeachbackScreenState extends State<TeachbackScreen> {
  final TextEditingController _answerController = TextEditingController();

  bool _submitted = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submitAnswer() {
  final answer = _answerController.text.trim();

  if (answer.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your answer before submitting.'),
      ),
    );
    return;
  }

  setState(() {
    _submitted = true;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teach-back'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let’s check your understanding',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Explain the instructions in your own words.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'What should you do at home after being discharged?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: TextField(
                  controller: _answerController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_submitted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withValues(alpha: 0.12),
                  ),
                  child: const Text(
                    'Answer submitted successfully.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_submitted) {
                      final session = TeachbackSession(
  dischargeRequest: widget.dischargeRequest,
  answer: _answerController.text.trim(),
);

context.push(
  '/results',
  extra: session,
);
                    } else {
                      _submitAnswer();
                    }
                  },
                  child: Text(
                    _submitted ? 'View Results' : 'Submit Answer',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}