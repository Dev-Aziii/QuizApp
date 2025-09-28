class Question {
  final String text;
  final List<String> options;
  final List<int> correctOptionIndexes;
  Question({
    required this.text,
    required this.options,
    required this.correctOptionIndexes,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] ?? "",
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndexes: List<int>.from(map['correctOptionIndexes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'options': options,
      'correctOptionIndexes': correctOptionIndexes,
    };
  }

  Question copyWith({
    String? text,
    List<String>? options,
    List<int>? correctOptionIndexes,
  }) {
    return Question(
      text: text ?? this.text,
      options: options ?? this.options,
      correctOptionIndexes: correctOptionIndexes ?? this.correctOptionIndexes,
    );
  }
}
