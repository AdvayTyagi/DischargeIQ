import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  // Tuning knobs — change these numbers if you want different rules.
  // ---------------------------------------------------------------

  // We want to ask at least this many questions in total, even if the
  // backend only sent us fewer to start with.
  static const int _minTotalQuestions = 5;

  // Never ask more than this many questions total, no matter what,
  // so a patient who keeps answering wrong doesn't get stuck forever.
  static const int _maxTotalQuestions = 10;

  // If a specific question is answered wrong, how many more times can
  // it come back around before we just accept the wrong answer and move on.
  static const int _maxAttemptsPerQuestion = 3;

  final TextEditingController _answerController = TextEditingController();

  // The working list of questions still left to ask. Unlike
  // widget.session.teachBackQuestions (which never changes), this list
  // can grow — a wrong answer puts that question back at the end of
  // this list so it gets asked again later.
  late List<TeachBackQuestion> _queue;

  // How many questions we've asked in total so far, counting repeats.
  int _totalAsked = 0;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.session.teachBackQuestions);
    _fillUpToMinimumIfNeeded();
  }

  // If the backend gave us fewer than _minTotalQuestions unique
  // questions, we re-use existing ones so there's still a reasonable
  // number of questions in the session. We can't invent brand new,
  // medically meaningful questions on the app side — that has to come
  // from the backend/AI side. This is just a fallback so the teach-back
  // doesn't feel too short if the AI only returned 2-3 questions.
  void _fillUpToMinimumIfNeeded() {
    if (_queue.isEmpty) return;

    final original = List<TeachBackQuestion>.from(_queue);
    int i = 0;
    while (_queue.length < _minTotalQuestions) {
      _queue.add(original[i % original.length]);
      i++;
    }
  }

  TeachBackQuestion get _currentQuestion => _queue.first;

  Future<void> _submitAnswer() async {
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
        _queue.removeAt(0); // this question is done for now either way

        final gotItWrong = question.correct == false;
        final canRetry = question.attempts < _maxAttemptsPerQuestion;
        final underCap = _totalAsked < _maxTotalQuestions;

        if (gotItWrong && canRetry && underCap) {
          // Wrong answer: put it back at the end of the line so the
          // patient gets asked this same point again later. This is
          // exactly what grows the total question count.
          _queue.add(question);
        }

        _answerController.clear();
      });

      if (_queue.isEmpty) {
        if (!mounted) return;
        context.push('/results', extra: widget.session);
      }
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

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      // Safety net in case build() runs after we've already navigated away.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Teach-back (question ${_totalAsked + 1})'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Question',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentQuestion.attempts > 0)
                          Text(
                            'Let’s try this one again',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600,
                            ),
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

              Expanded(
                child: TextField(
                  controller: _answerController,
                  maxLines: null,
                  expands: true,
                  enabled: !_isSubmitting,
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

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Answer', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}