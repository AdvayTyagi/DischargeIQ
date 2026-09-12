import 'package:flutter/material.dart';

import '../../core/models/teachback_session.dart';

class ResultsScreen extends StatelessWidget {
  final TeachbackSession teachbackSession;

  const ResultsScreen({
    super.key,
    required this.teachbackSession,
  });

  // Mock result for now.
  // Later this will come from the backend response contract.
  static const String result = 'green';

  @override
  Widget build(BuildContext context) {
    final bool isGreen = result == 'green';
    final bool isAmber = result == 'amber';

    final String title = isGreen
        ? 'Good Understanding'
        : isAmber
            ? 'Needs Clarification'
            : 'Needs Attention';

    final String message = isGreen
        ? 'You have demonstrated a good understanding of your discharge instructions.'
        : isAmber
            ? 'Some parts of your answer may need further clarification.'
            : 'Please review your discharge instructions and speak with a healthcare professional if needed.';

    final IconData icon = isGreen
        ? Icons.check_circle
        : isAmber
            ? Icons.warning_amber_rounded
            : Icons.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              Icon(
                icon,
                size: 90,
              ),

              const SizedBox(height: 24),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: const Column(
                  children: [
                    Text(
                      'Understanding Score',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '85%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your teach-back answer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      teachbackSession.answer,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16),
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