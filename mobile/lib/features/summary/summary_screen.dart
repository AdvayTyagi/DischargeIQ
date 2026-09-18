import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/models/session.dart';
import '../../core/l10n.dart';

class SummaryScreen extends StatefulWidget {
  final DischargeSession session;

  static const int _maxPointsToShow = 5;

  const SummaryScreen({
    super.key,
    required this.session,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final FlutterTts _tts = FlutterTts();

  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();

    _tts.setCompletionHandler(() {
      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speakInstructions() async {
    final points = widget.session.simplifiedInstructions
        .take(SummaryScreen._maxPointsToShow)
        .toList();

    if (points.isEmpty) {
      return;
    }

    final text = points
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('. ');

    await _tts.stop();

    await _tts.setSpeechRate(0.45);

    if (!mounted) return;

    setState(() {
      _isSpeaking = true;
    });

    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointsToShow = widget.session.simplifiedInstructions
        .take(SummaryScreen._maxPointsToShow)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.get('simplifiedTitle', widget.session.preferredLanguage)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.get('heresWhatYouNeed', widget.session.preferredLanguage),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                L10n.get('keyPoints', widget.session.preferredLanguage),
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  itemCount: pointsToShow.length,
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
                child: OutlinedButton.icon(
                  onPressed: _isSpeaking
                      ? _stopSpeaking
                      : _speakInstructions,
                  icon: Icon(
                    _isSpeaking
                        ? Icons.stop
                        : Icons.volume_up,
                  ),
                  label: Text(
                    _isSpeaking
                        ? L10n.get('stopReading', widget.session.preferredLanguage)
                        : L10n.get('readInstructions', widget.session.preferredLanguage),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: () {
                  context.push(
                    '/teachback',
                    extra: widget.session,
                  );
                },
                child: Text(
                  L10n.get('continueTeachBack', widget.session.preferredLanguage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimplifiedPoint extends StatelessWidget {
  final int number;
  final String text;

  const _SimplifiedPoint({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}