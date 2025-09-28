import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsreviewer_app/model/question.dart';
import 'package:itsreviewer_app/model/quiz.dart';
import 'package:itsreviewer_app/theme/theme.dart';

// (Same imports)

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
    _timeLimitController = TextEditingController(
      text: widget.quiz.timeLimit.toString(),
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
        SnackBar(content: Text("Quiz must have at least one question")),
      );
    }
  }

  Future<void> _updateQuiz() async {
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

      final updateQuiz = widget.quiz.copyWith(
        title: _titleController.text.trim(),
        timeLimit: int.parse(_timeLimitController.text),
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
            content: Text("Quiz updated successfully"),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        title: Text("Edit Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Enter quiz title" : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _timeLimitController,
              decoration: InputDecoration(
                labelText: "Time Limit (minutes)",
                prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Enter time limit";
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return "Enter valid time limit";
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ..._questionsItems.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                        ],
                      ),
                      TextFormField(
                        controller: question.questionController,
                        decoration: InputDecoration(labelText: "Question"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter question"
                            : null,
                      ),
                      SizedBox(height: 10),
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
                                    value == null || value.isEmpty
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
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addQuestion,
                label: Text("Add Question"),
                icon: Icon(Icons.add),
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
