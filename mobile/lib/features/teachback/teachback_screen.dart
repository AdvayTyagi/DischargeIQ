import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/models/session.dart';
import '../../core/services/discharge_api.dart';
import '../../core/l10n.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();

  final FlutterTts _tts = FlutterTts();

  final TextEditingController _answerController =
      TextEditingController();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isSubmitting = false;

  final List<TeachBackQuestion> _queue = [];

  int _totalAsked = 0;

  static const int _maxAttemptsPerQuestion = 2;
  static const int _maxTotalQuestions = 8;
  static const int _minTotalQuestions = 5;

  @override
  void initState() {
    super.initState();

    _initializeSpeech();
    _initializeQuestions();
  }

  // ---------------------------------------------------------------
  // LANGUAGE
  // ---------------------------------------------------------------

  String _getLanguageCode() {
    switch (widget.session.preferredLanguage) {
      case 'hi':
        return 'hi-IN';

      case 'ta':
        return 'ta-IN';

      case 'en':
      default:
        return 'en-IN';
    }
  }

  // ---------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------

  Future<void> _initializeSpeech() async {
    try {
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
              content: Text(
                '${L10n.get('speechError', widget.session.preferredLanguage)}${error.errorMsg}',
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });

      await _tts.setSpeechRate(0.45);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _initializeQuestions() {
    final original = List<TeachBackQuestion>.from(
      widget.session.teachBackQuestions,
    );

    _queue.clear();

    _queue.addAll(original);

    if (original.isEmpty) {
      return;
    }

    int i = 0;

    while (_queue.length < _minTotalQuestions) {
      _queue.add(
        original[i % original.length],
      );

      i++;
    }

    if (_queue.length > _maxTotalQuestions) {
      _queue.removeRange(
        _maxTotalQuestions,
        _queue.length,
      );
    }
  }

  // ---------------------------------------------------------------
  // CURRENT QUESTION
  // ---------------------------------------------------------------

  TeachBackQuestion get _currentQuestion {
    return _queue.first;
  }

  // ---------------------------------------------------------------
  // TEXT TO SPEECH
  // ---------------------------------------------------------------

  Future<void> _speakQuestion() async {
    if (_queue.isEmpty) return;

    await _tts.stop();

    await _tts.setLanguage(
      _getLanguageCode(),
    );

    await _tts.setSpeechRate(0.45);

    await _tts.speak(
      _currentQuestion.question,
    );
  }

  Future<void> _speakAgain() async {
    _clearAnswer();

    await _tts.stop();

    await _speakQuestion();
  }

  // ---------------------------------------------------------------
  // ANSWER INPUT
  // ---------------------------------------------------------------

  void _clearAnswer() {
    _answerController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  void _updateAnswer(String value) {
    setState(() {});
  }

  // ---------------------------------------------------------------
  // SPEECH TO TEXT
  // ---------------------------------------------------------------

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.get('speechNotAvailable', widget.session.preferredLanguage),
          ),
        ),
      );

      return;
    }

    await _tts.stop();

    _answerController.clear();

    if (!mounted) return;

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;

        final words = result.recognizedWords;

        _answerController.value = TextEditingValue(
          text: words,
          selection: TextSelection.collapsed(
            offset: words.length,
          ),
        );

        setState(() {});
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: _getLanguageCode(),
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
  // SUBMIT ANSWER
  // ---------------------------------------------------------------

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.get('pleaseType', widget.session.preferredLanguage),
          ),
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
      final gradeResponse = await DischargeApi.gradeAnswer(
        session: widget.session,
        question: question,
        patientAnswer: answer,
      );

      _totalAsked += 1;

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // -------------------------------------------------------------
      // INCORRECT ANSWER
      // -------------------------------------------------------------

      if (!gradeResponse.correct) {
        await _showIncorrectAnswerDialog(
          question,
        );

        if (!mounted) return;

        final canRetry =
            question.attempts < _maxAttemptsPerQuestion;

        final underCap =
            _totalAsked < _maxTotalQuestions;

        if (canRetry && underCap) {
          setState(() {
            _queue.removeAt(0);
            _queue.add(question);
            _answerController.clear();
          });

          return;
        }
      }

      // -------------------------------------------------------------
      // CORRECT ANSWER OR NO MORE RETRIES
      // -------------------------------------------------------------

      setState(() {
        _queue.removeAt(0);
        _answerController.clear();
      });

      if (_queue.isEmpty) {
        if (!mounted) return;

        context.push(
          '/results',
          extra: widget.session,
        );

        return;
      }

      await _speakQuestion();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            L10n.get('couldNotCheck', widget.session.preferredLanguage),
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------
  // INCORRECT ANSWER DIALOG
  // ---------------------------------------------------------------

  Future<void> _showIncorrectAnswerDialog(
    TeachBackQuestion question,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.cancel,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  L10n.get('notQuite', widget.session.preferredLanguage),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.patientAnswer != null) ...[
                  Text(
                    L10n.get('yourAnswerLabel', widget.session.preferredLanguage),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.patientAnswer!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (question.feedback != null) ...[
                  Text(
                    L10n.get('feedback', widget.session.preferredLanguage),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.feedback!,
                  ),
                  const SizedBox(height: 16),
                ],
                if (question.correctAnswer != null) ...[
                  Text(
                    L10n.get('correctAnswer', widget.session.preferredLanguage),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.correctAnswer!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                L10n.get('continue', widget.session.preferredLanguage),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _answerController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            L10n.get('teachBack', widget.session.preferredLanguage),
          ),
        ),
        body: Center(
          child: Text(
            L10n.get('noQuestions', widget.session.preferredLanguage),
          ),
        ),
      );
    }

    final question = _currentQuestion;

    final progress = _totalAsked + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.get('teachBack', widget.session.preferredLanguage),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // -------------------------------------------------------
            // PROGRESS
            // -------------------------------------------------------

            Text(
              '${L10n.get('question', widget.session.preferredLanguage)} $progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress / _maxTotalQuestions,
            ),

            const SizedBox(height: 28),

            // -------------------------------------------------------
            // QUESTION
            // -------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.get('teachBackQuestion', widget.session.preferredLanguage),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSubmitting ? null : _speakQuestion,
                      icon: const Icon(
                        Icons.volume_up,
                      ),
                      label: Text(
                        L10n.get('readQuestion', widget.session.preferredLanguage),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------------
            // TYPE OR SPEAK
            // -------------------------------------------------------

            Text(
              L10n.get('yourAnswer', widget.session.preferredLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              L10n.get('typeOrSpeak', widget.session.preferredLanguage),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            // -------------------------------------------------------
            // TEXT INPUT
            // -------------------------------------------------------

            TextField(
              controller: _answerController,
              enabled: !_isSubmitting,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onChanged: _updateAnswer,
              decoration: InputDecoration(
                hintText: L10n.get('typeHere', widget.session.preferredLanguage),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    width: 2,
                  ),
                ),
                suffixIcon:
                    _answerController.text.isNotEmpty
                        ? IconButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : _clearAnswer,
                            icon: const Icon(
                              Icons.clear,
                            ),
                          )
                        : null,
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------------
            // SPEECH AREA
            // -------------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isListening
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _isListening
                        ? Icons.mic
                        : Icons.mic_none,
                    size: 48,
                    color: _isListening
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : Colors.grey,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _isListening
                        ? L10n.get('listening', widget.session.preferredLanguage)
                        : L10n.get('speakAnswer', widget.session.preferredLanguage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -------------------------------------------------
                  // MICROPHONE BUTTON
                  // -------------------------------------------------

                  SizedBox(
                    width: 72,
                    height: 72,
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
                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _isListening
                        ? L10n.get('tapStop', widget.session.preferredLanguage)
                        : L10n.get('spokenWillAppear', widget.session.preferredLanguage),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------------
            // SPEAK AGAIN / CLEAR
            // -------------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isSubmitting ? null : _speakAgain,
                    icon: const Icon(
                      Icons.volume_up,
                    ),
                    label: Text(
                      L10n.get('questionAgain', widget.session.preferredLanguage),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isSubmitting ||
                                _answerController.text.isEmpty
                            ? null
                            : _clearAnswer,
                    icon: const Icon(
                      Icons.clear,
                    ),
                    label: Text(
                      L10n.get('clear', widget.session.preferredLanguage),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------------
            // SUBMIT
            // -------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting ||
                            _answerController.text
                                .trim()
                                .isEmpty
                        ? null
                        : _submitAnswer,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                      ),
                label: Text(
                  _isSubmitting
                      ? L10n.get('checking', widget.session.preferredLanguage)
                      : L10n.get('submitAnswer', widget.session.preferredLanguage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}