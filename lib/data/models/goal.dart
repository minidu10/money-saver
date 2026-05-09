class Goal {
  final String id;
  final String title;
  final double target;
  final double saved;
  final DateTime? deadline;

  const Goal({
    required this.id,
    required this.title,
    required this.target,
    required this.saved,
    this.deadline,
  });

  double get progress => target == 0 ? 0 : (saved / target).clamp(0, 1);
}
