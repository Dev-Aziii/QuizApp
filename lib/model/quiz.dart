import 'package:itsreviewer_app/model/question.dart';

class Quiz {
  final String id;
  final String title;
  final String categoryId;
  final int? timeLimit; // nullable
  final List<Question> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quiz({
    required this.id,
    required this.title,
    required this.categoryId,
    this.timeLimit,
    required this.questions,
    required this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> map) {
    return Quiz(
      id: id,
      title: map['title'] ?? "",
      categoryId: map['categoryId'] ?? "",
      timeLimit: map['timeLimit'],
      questions: ((map['questions'] ?? []) as List)
          .map((e) => Question.fromMap(e))
          .toList(),
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isUpdate = false}) {
    final map = {
      'title': title,
      'categoryId': categoryId,
      'questions': questions.map((e) => e.toMap()).toList(),
      if (isUpdate) 'updatedAt': DateTime.now(),
      'createdAt': createdAt ?? DateTime.now(),
    };

    if (timeLimit != null) {
      map['timeLimit'] = timeLimit!;
    }

    return map;
  }

  Quiz copyWith({
    String? title,
    String? categoryId,
    int? timeLimit,
    List<Question>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      timeLimit: timeLimit ?? this.timeLimit,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
