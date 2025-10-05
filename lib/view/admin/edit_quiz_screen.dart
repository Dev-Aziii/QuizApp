import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsreviewer_app/model/question.dart';
import 'package:itsreviewer_app/model/quiz.dart';
import 'package:itsreviewer_app/theme/theme.dart';

class EditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  const EditQuizScreen({super.key, required this.quiz});

  @override
  State<EditQuizScreen> createState() => _EditQuizScreenState();
}

class QuestionFormItem {
  final TextEditingController questionController;
  final List<TextEditingController> optionsControllers;
  List<int> correctOptionIndexes;

  QuestionFormItem({
    required this.questionController,
    required this.optionsControllers,
    required this.correctOptionIndexes,
  });

  void dispose() {
    questionController.dispose();
    for (var element in optionsControllers) {
      element.dispose();
    }
  }
}

class _EditQuizScreenState extends State<EditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _timeLimitController;
  bool _noTimeLimit = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  late List<QuestionFormItem> _questionsItems;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    for (var item in _questionsItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _initData() {
    _titleController = TextEditingController(text: widget.quiz.title);
    _noTimeLimit = widget.quiz.timeLimit == null;
    _timeLimitController = TextEditingController(
      text: widget.quiz.timeLimit != null
          ? widget.quiz.timeLimit.toString()
          : "",
    );

    _questionsItems = widget.quiz.questions.map((question) {
      return QuestionFormItem(
        questionController: TextEditingController(text: question.text),
        optionsControllers: question.options
            .map((option) => TextEditingController(text: option))
            .toList(),
        correctOptionIndexes: List<int>.from(question.correctOptionIndexes),
      );
    }).toList();
  }

  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFormItem(
          questionController: TextEditingController(),
          optionsControllers: List.generate(4, (e) => TextEditingController()),
          correctOptionIndexes: [],
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questionsItems.length > 1) {
      setState(() {
        _questionsItems[index].dispose();
        _questionsItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz must have at least one question")),
      );
    }
  }

  Future<void> _updateQuiz() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
              text: item.questionController.text.trim(),
              options: item.optionsControllers
                  .map((e) => e.text.trim())
                  .toList(),
              correctOptionIndexes: item.correctOptionIndexes,
            ),
          )
          .toList();

      final int? timeLimit = _noTimeLimit
          ? null
          : int.parse(_timeLimitController.text.trim());

      final updateQuiz = widget.quiz.copyWith(
        title: _titleController.text.trim(),
        timeLimit: timeLimit,
        questions: questions,
        createdAt: widget.quiz.createdAt,
      );

      await _firestore
          .collection("quizzes")
          .doc(widget.quiz.id)
          .update(updateQuiz.toMap(isUpdate: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Quiz updated successfully"),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update quiz"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          "Edit Quiz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updateQuiz,
            icon: Icon(Icons.save, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Quiz Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? "Enter quiz title"
                  : null,
            ),
            const SizedBox(height: 16),

            // Time limit + switch
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _timeLimitController,
                    decoration: InputDecoration(
                      labelText: "Time Limit (minutes)",
                      prefixIcon: Icon(
                        Icons.timer,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_noTimeLimit,
                    validator: (value) {
                      if (_noTimeLimit) return null;
                      if (value == null || value.trim().isEmpty) {
                        return "Enter time limit";
                      }
                      final number = int.tryParse(value.trim());
                      if (number == null || number <= 0) {
                        return "Enter valid time limit";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text("No Time Limit"),
                    Switch(
                      value: _noTimeLimit,
                      onChanged: (v) {
                        setState(() {
                          _noTimeLimit = v;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions
            ..._questionsItems.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Question ${index + 1}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (_questionsItems.length > 1)
                            IconButton(
                              onPressed: () => _removeQuestion(index),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Question text
                      TextFormField(
                        controller: question.questionController,
                        decoration: const InputDecoration(
                          labelText: "Question",
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? "Enter question"
                            : null,
                      ),
                      const SizedBox(height: 8),
                      // Options
                      ...question.optionsControllers.asMap().entries.map((opt) {
                        final optIndex = opt.key;
                        final controller = opt.value;
                        final isChecked = question.correctOptionIndexes
                            .contains(optIndex);

                        return Row(
                          children: [
                            Checkbox(
                              activeColor: AppTheme.primaryColor,
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    question.correctOptionIndexes.add(optIndex);
                                  } else {
                                    question.correctOptionIndexes.remove(
                                      optIndex,
                                    );
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: "Option ${optIndex + 1}",
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? "Enter option"
                                    : null,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addQuestion,
                label: const Text("Add Question"),
                icon: const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
