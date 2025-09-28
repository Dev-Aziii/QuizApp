import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:itsreviewer_app/model/question.dart';
import 'package:itsreviewer_app/model/quiz.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'package:itsreviewer_app/view/user/quiz_result_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late PageController _pageController;

  int _currentQuestionIndex = 0;
  final Map<int, Set<int>> _selectedAnswers = {};

  int _totalMinutes = 0;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _totalMinutes = widget.quiz.timeLimit;
    _remainingMinutes = _totalMinutes;
    _remainingSeconds = 0;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          if (_remainingMinutes > 0) {
            _remainingMinutes--;
            _remainingSeconds = 59;
          } else {
            _timer?.cancel();
            _completeQuiz();
          }
        }
      });
    });
  }

  bool _isGoingForward = true;

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _isGoingForward = true;
        _currentQuestionIndex++;
      });
    } else {
      _completeQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _isGoingForward = false;
        _currentQuestionIndex--;
      });
    }
  }

  void _completeQuiz() {
    _timer?.cancel();
    int correctAnswers = _calculateScore();

    _selectedAnswers.map(
      (key, value) => MapEntry(key, value.isEmpty ? null : value.first),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          quiz: widget.quiz,
          totalQuestions: widget.quiz.questions.length,
          correctAnswers: correctAnswers,
          selectedAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  int _calculateScore() {
    double totalScore = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      final question = widget.quiz.questions[i];
      final correctIndexes = question.correctOptionIndexes.toSet();
      final selectedIndexes = _selectedAnswers[i] ?? {};

      if (selectedIndexes.isEmpty) continue;

      int correctSelected = selectedIndexes
          .where((e) => correctIndexes.contains(e))
          .length;
      int incorrectSelected = selectedIndexes
          .where((e) => !correctIndexes.contains(e))
          .length;

      if (incorrectSelected == 0 && correctSelected > 0) {
        totalScore += correctSelected / correctIndexes.length;
      }
    }
    return totalScore.floor();
  }

  Color _getTimerColor() {
    int totalSeconds = _totalMinutes * 60;
    int remainingSeconds = _remainingMinutes * 60 + _remainingSeconds;
    double progress = 1 - (remainingSeconds / totalSeconds);

    if (progress < 0.5) return Colors.green;
    if (progress < 0.75) return Colors.orange;
    return Colors.redAccent;
  }

  void _toggleAnswer(int optionIndex) {
    setState(() {
      final selected = _selectedAnswers[_currentQuestionIndex] ?? {};
      if (selected.contains(optionIndex)) {
        selected.remove(optionIndex);
      } else {
        selected.add(optionIndex);
      }
      _selectedAnswers[_currentQuestionIndex] = selected;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Animate(
                    key: ValueKey<int>(_currentQuestionIndex),
                    child: _buildQuestionCard(
                      widget.quiz.questions[_currentQuestionIndex],
                      _currentQuestionIndex,
                    ),
                  )
                  .fade(duration: 300.ms)
                  .slide(
                    begin: _isGoingForward
                        ? const Offset(1, 0)
                        : const Offset(-1, 0),
                    curve: Curves.easeInOut,
                    duration: 300.ms,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: AppTheme.textPrimaryColor,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: CircularProgressIndicator(
                      value:
                          (_remainingMinutes * 60 + _remainingSeconds) /
                          (_totalMinutes * 60),
                      strokeWidth: 5,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTimerColor(),
                      ),
                    ),
                  ),
                  Text(
                    '$_remainingMinutes:${_remainingSeconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getTimerColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
            ),
            duration: const Duration(milliseconds: 300),
            builder: (context, progress, child) {
              return LinearProgressIndicator(
                borderRadius: BorderRadius.circular(10),
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 6,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    final selected = _selectedAnswers[index] ?? {};
    bool isMultiple = question.correctOptionIndexes.length > 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${index + 1}",
            style: TextStyle(fontSize: 16, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ...question.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final option = entry.value;

            if (isMultiple) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CheckboxListTile(
                  value: selected.contains(optionIndex),
                  activeColor: AppTheme.secondaryColor,
                  onChanged: (value) => _toggleAnswer(optionIndex),
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              );
            } else {
              int? selectedIndex = selected.isEmpty ? null : selected.first;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: RadioListTile<int>(
                  value: optionIndex,
                  groupValue: selectedIndex,
                  activeColor: AppTheme.secondaryColor,
                  onChanged: (value) {
                    if (value != null) _toggleAnswer(value);
                  },
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              // Previous Button
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex > 0
                        ? _previousQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.grey, // Different color for clarity
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Previous",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Next / Finish Button
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: selected.isNotEmpty ? _nextQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentQuestionIndex == widget.quiz.questions.length - 1
                          ? "Finish Quiz"
                          : 'Next Question',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
