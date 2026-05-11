class Goal {
  final String id;
  final String title;
  final double target;
  final double saved;
  final DateTime? deadline;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.saved,
    required this.createdAt,
    this.deadline,
  });

  double get progress => target == 0 ? 0 : (saved / target).clamp(0, 1);
  bool get isComplete => saved >= target;

  Goal copyWith({
    String? title,
    double? target,
    double? saved,
    DateTime? deadline,
    bool clearDeadline = false,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        target: target ?? this.target,
        saved: saved ?? this.saved,
        createdAt: createdAt,
        deadline: clearDeadline ? null : (deadline ?? this.deadline),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'target': target,
        'saved': saved,
        'deadline': deadline?.toUtc().toIso8601String(),
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory Goal.fromMap(String id, Map<String, dynamic> m) => Goal(
        id: id,
        title: m['title'] as String,
        target: (m['target'] as num).toDouble(),
        saved: (m['saved'] as num?)?.toDouble() ?? 0,
        deadline: m['deadline'] == null
            ? null
            : DateTime.parse(m['deadline'] as String),
        createdAt: m['createdAt'] == null
            ? DateTime.now()
            : DateTime.parse(m['createdAt'] as String),
      );
}
