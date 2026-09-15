import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/session.dart';

class SummaryScreen extends StatelessWidget {
  final DischargeSession session;

  // If the backend gives us more than this many points, we only show
  // the first few — the idea is a short, scannable list, not a wall
  // of bullets. If it gives us fewer, we just show what we have.
  static const int _maxPointsToShow = 5;

  const SummaryScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    // Take at most _maxPointsToShow items from the full list.
    final pointsToShow = session.simplifiedInstructions
        .take(_maxPointsToShow)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Instructions, Simplified'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Here’s what you need to know',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'The key points from your discharge instructions.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              // Expanded + ListView so this scrolls if the list is long
              // on a small screen, instead of overflowing.
              Expanded(
                child: ListView.separated(
                  itemCount: pointsToShow.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _SimplifiedPoint(
                      number: index + 1,
                      text: pointsToShow[index],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/teachback', extra: session);
                  },
                  child: const Text(
                    'Continue to Teach-back',
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

// One numbered row: a circle with the number, and the point's text next
// to it. Pulled out as its own small widget just to keep build() tidy.
class _SimplifiedPoint extends StatelessWidget {
  final int number;
  final String text;

  const _SimplifiedPoint({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey.shade100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.black87,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}