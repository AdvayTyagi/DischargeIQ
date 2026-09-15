import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/models/session.dart';
import '../../core/services/discharge_api.dart';

class TeachbackScreen extends StatefulWidget {
  final DischargeSession session;

  const TeachbackScreen({
    super.key,
    required this.session,
  });

  @override
  State<TeachbackScreen> createState() => _TeachbackScreenState();
}

class _TeachbackScreenState extends State<TeachbackScreen> {
  // ---------------------------------------------------------------
  // Question rules
  // ---------------------------------------------------------------

  static const int _minTotalQuestions = 5;
  static const int _maxTotalQuestions = 10;
  static const int _maxAttemptsPerQuestion = 3;

  // ---------------------------------------------------------------
  // Voice services
  // ---------------------------------------------------------------

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late List<TeachBackQuestion> _queue;

  int _totalAsked = 0;

  bool _isSubmitting = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  String _transcript = '';

  @override
  void initState() {
    super.initState();

    _queue = List.from(widget.session.teachBackQuestions);
    _fillUpToMinimumIfNeeded();

    _initializeVoice();
  }

  // ---------------------------------------------------------------
  // Voice initialization
  // ---------------------------------------------------------------

  Future<void> _initializeVoice() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isListening = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech recognition error: ${error.errorMsg}'),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _speechAvailable = available;
    });

    // Read the first question aloud automatically.
    await _speakQuestion();
  }

  // ---------------------------------------------------------------
  // Text-to-speech
  // ---------------------------------------------------------------

  Future<void> _speakQuestion() async {
    if (_queue.isEmpty) return;

    await _tts.stop();

    await _tts.speak(_currentQuestion.question);
  }

  // ---------------------------------------------------------------
  // Speech-to-text
  // ---------------------------------------------------------------

  Future<void> _startListening() async {
    if (_isSubmitting) return;

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available on this device.',
          ),
        ),
      );
      return;
    }

    await _tts.stop();

    setState(() {
      _transcript = '';
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          _transcript = result.recognizedWords;
        });
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  // ---------------------------------------------------------------
  // Question queue
  // ---------------------------------------------------------------

  TeachBackQuestion get _currentQuestion => _queue.first;

  void _fillUpToMinimumIfNeeded() {
    if (_queue.isEmpty) return;

    final original = List<TeachBackQuestion>.from(_queue);

    int i = 0;

    while (_queue.length < _minTotalQuestions) {
      _queue.add(original[i % original.length]);
      i++;
    }
  }

  // ---------------------------------------------------------------
  // Submit voice transcript
  // ---------------------------------------------------------------

  Future<void> _submitAnswer() async {
    final answer = _transcript.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please speak your answer first.'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _stopListening();
    }

    await _tts.stop();

    setState(() {
      _isSubmitting = true;
    });

    final question = _currentQuestion;

    try {
      await DischargeApi.gradeAnswer(
        session: widget.session,
        question: question,
        patientAnswer: answer,
      );

      question.attempts += 1;
      _totalAsked += 1;

      if (!mounted) return;

      setState(() {
        _queue.removeAt(0);

        final gotItWrong = question.correct == false;
        final canRetry = question.attempts < _maxAttemptsPerQuestion;
        final underCap = _totalAsked < _maxTotalQuestions;

        if (gotItWrong && canRetry && underCap) {
          _queue.add(question);
        }

        _transcript = '';
      });

      if (_queue.isEmpty) {
        if (!mounted) return;

        context.push(
          '/results',
          extra: widget.session,
        );

        return;
      }

      // Automatically read the next question.
      await _speakQuestion();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not grade that answer: $e'),
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

  // ---------------------------------------------------------------
  // Speak again
  // ---------------------------------------------------------------

  Future<void> _speakAgain() async {
    await _stopListening();

    setState(() {
      _transcript = '';
    });

    await _speakQuestion();
  }

  // ---------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teach-back (question ${_totalAsked + 1})',
        ),
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
                'Listen to the question and answer using your voice.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 24),

              // ---------------------------------------------------
              // QUESTION
              // ---------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Question',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          tooltip: 'Read question aloud',
                          onPressed:
                              _isSubmitting ? null : _speakQuestion,
                          icon: const Icon(Icons.volume_up),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _currentQuestion.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------------------------------
              // VOICE AREA
              // ---------------------------------------------------

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isListening
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isListening
                            ? Icons.mic
                            : Icons.mic_none,
                        size: 64,
                        color: _isListening
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        _isListening
                            ? 'Listening...'
                            : 'Tap the microphone and speak',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Microphone button
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: FloatingActionButton(
                          onPressed: _isSubmitting
                              ? null
                              : (_isListening
                                  ? _stopListening
                                  : _startListening),
                          child: Icon(
                            _isListening
                                ? Icons.stop
                                : Icons.mic,
                            size: 32,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------
                      // TRANSCRIPT
                      // ------------------------------------------------

                      if (_transcript.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your answer:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _transcript,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------------------------------------------
              // BUTTONS
              // ---------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : _speakAgain,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Speak Again'),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSubmitting || _transcript.trim().isEmpty
                              ? null
                              : _submitAnswer,
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isSubmitting
                            ? 'Checking...'
                            : 'Continue',
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}