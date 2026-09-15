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

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: Column(
                children: [
                  Text(
                    L10n.get('understandingScore', session.preferredLanguage),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$correctCount ${L10n.get('outOf', session.preferredLanguage)} $totalGraded ${L10n.get('correct', session.preferredLanguage)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
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

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          wasCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: wasCorrect
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            q.question,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (q.patientAnswer != null) ...[
                      const SizedBox(height: 8),

                      Text(
                        '${L10n.get('answerPrefix', session.preferredLanguage)} ${q.patientAnswer}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],

                    if (q.feedback != null) ...[
                      const SizedBox(height: 6),

                      Text(
                        q.feedback!,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    // Show the correct answer when the patient's answer
                    // was incorrect.
                    if (!wasCorrect && q.correctAnswer != null) ...[
                      const SizedBox(height: 12),

                      Text(
                        L10n.get('correctAnswer', session.preferredLanguage),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        q.correctAnswer!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    if (q.attempts > 1) ...[
                      const SizedBox(height: 6),

                      Text(
                        '${L10n.get('took', session.preferredLanguage)} ${q.attempts} ${L10n.get('tries', session.preferredLanguage)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
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