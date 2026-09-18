import 'package:flutter/material.dart';

import '../../core/models/session.dart';
import '../../core/l10n.dart';

class ResultsScreen extends StatelessWidget {
  final DischargeSession session;

  const ResultsScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final (correctCount, totalGraded) = session.scoreSoFar;

    final percent =
        totalGraded == 0 ? 0 : ((correctCount / totalGraded) * 100).round();

    // Simple overall verdict based on the percentage of correct answers.
    // The backend only gives right/wrong per question — this is where
    // that gets turned into an overall green/amber/red picture.

    final Color verdictColor;
    final IconData verdictIcon;
    final String title;
    final String message;

    if (percent >= 80) {
      verdictColor = Colors.green;
      verdictIcon = Icons.check_circle;
      title = L10n.get('goodUnderstanding', session.preferredLanguage);
      message = L10n.get('goodDesc', session.preferredLanguage);
    } else if (percent >= 50) {
      verdictColor = Colors.orange;
      verdictIcon = Icons.warning_amber_rounded;
      title = L10n.get('needsClarification', session.preferredLanguage);
      message = L10n.get('clarificationDesc', session.preferredLanguage);
    } else {
      verdictColor = Colors.red;
      verdictIcon = Icons.error;
      title = L10n.get('needsAttention', session.preferredLanguage);
      message = L10n.get('attentionDesc', session.preferredLanguage);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.get('results', session.preferredLanguage)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            Icon(
              verdictIcon,
              size: 90,
              color: verdictColor,
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

            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: totalGraded == 0 ? 0 : correctCount / totalGraded,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: verdictColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: verdictColor,
                      ),
                    ),
                    Text(
                      '$correctCount / $totalGraded',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              L10n.get('questionByQuestion', session.preferredLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...session.teachBackQuestions.map((q) {
              final bool wasCorrect = q.correct == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: wasCorrect ? Colors.green.shade200 : Colors.red.shade200, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            wasCorrect ? Icons.check_circle : Icons.cancel,
                            color: wasCorrect ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.question,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (q.patientAnswer != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.person_outline, size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.patientAnswer!,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!wasCorrect && q.correctAnswer != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 20, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.correctAnswer!,
                                  style: TextStyle(fontSize: 14, color: Colors.green.shade800, fontWeight: FontWeight.w500, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                child: Text(
                  L10n.get('done', session.preferredLanguage),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}