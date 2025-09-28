import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itsreviewer_app/model/category.dart';
import 'package:itsreviewer_app/model/question.dart';
import 'package:itsreviewer_app/model/quiz.dart';
import 'package:itsreviewer_app/theme/theme.dart';
import 'dart:developer';

class AddQuizScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  const AddQuizScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

// Models
class QuestionFromItem {
  final TextEditingController questionController;
  final List<TextEditingController> optionsControllers;
  List<int> correctOptionIndexes;

  QuestionFromItem({
    required this.questionController,
    required this.optionsControllers,
    required this.correctOptionIndexes,
  });

  void dispose() {
    questionController.dispose();
    for (var c in optionsControllers) {
      c.dispose();
    }
  }
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _selectedCategoryId;
  final List<QuestionFromItem> _questionsItems = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _addQuestion(); // initialize with one question
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();

    // Dispose all question items
    for (var item in _questionsItems) {
      item.dispose();
    }

    super.dispose();
  }

  /// Add a new empty question
  void _addQuestion() {
    setState(() {
      _questionsItems.add(
        QuestionFromItem(
          questionController: TextEditingController(),
          optionsControllers: List.generate(4, (_) => TextEditingController()),
          correctOptionIndexes: [],
        ),
      );
    });
  }

  /// Remove a question by index
  void _removeQuestion(int index) {
    setState(() {
      _questionsItems[index].dispose();
      _questionsItems.removeAt(index);
    });
  }

  /// Save quiz to Firestore
  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final questions = _questionsItems
          .map(
            (item) => Question(
              text: item.questionController.text.trim(),
              options: item.optionsControllers
                  .map((c) => c.text.trim())
                  .toList(),
              correctOptionIndexes: item.correctOptionIndexes,
            ),
          )
          .toList();

      final docRef = _firestore.collection("quizzes").doc();

      await docRef.set(
        Quiz(
          id: docRef.id,
          title: _titleController.text.trim(),
          categoryId: _selectedCategoryId!,
          timeLimit: int.parse(_timeLimitController.text.trim()),
          questions: questions,
          createdAt: DateTime.now(),
          updatedAt: null,
        ).toMap(),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Quiz added successfully"),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      log("Failed to add quiz", error: e, stackTrace: stack);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add quiz"),
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
        title: Text(
          widget.categoryName != null
              ? "Add ${widget.categoryName} Quiz"
              : "Add Quiz Question",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveQuiz,
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
            const Text(
              "Quiz Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                hintText: "Enter quiz title",
                prefixIcon: Icon(Icons.title, color: AppTheme.primaryColor),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Please enter quiz title" : null,
            ),
            const SizedBox(height: 16),

            // Category dropdown if no preselected category
            if (widget.categoryId == null)
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('categories')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text("Error loading categories");
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = snapshot.data!.docs
                      .map(
                        (doc) => Category.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: "Category",
                      hintText: "Select Category",
                      prefixIcon: Icon(
                        Icons.category,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) =>
                        v == null ? "Please select a category" : null,
                  );
                },
              ),
            const SizedBox(height: 20),

            // Time limit
            TextFormField(
              controller: _timeLimitController,
              decoration: InputDecoration(
                labelText: "Time Limit (in minutes)",
                hintText: "Enter Time Limit",
                prefixIcon: Icon(Icons.timer, color: AppTheme.primaryColor),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return "Please enter time limit";
                final n = int.tryParse(v);
                if (n == null || n <= 0) {
                  return "Please enter a valid time limit";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Questions list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Questions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Question"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question cards
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
                      // Question header + delete button
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
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: question.questionController,
                        decoration: InputDecoration(
                          labelText: "Question",
                          hintText: "Enter question",
                          prefixIcon: Icon(
                            Icons.question_mark,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Please enter question"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Options
                      ...question.optionsControllers.asMap().entries.map((
                        optEntry,
                      ) {
                        final optIndex = optEntry.key;
                        final controller = optEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: AppTheme.primaryColor,
                                value: question.correctOptionIndexes.contains(
                                  optIndex,
                                ),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      question.correctOptionIndexes.add(
                                        optIndex,
                                      );
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
                                    hintText: "Enter Option",
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? "Please enter option"
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
            // Save button
            Center(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuiz,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Quiz",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
