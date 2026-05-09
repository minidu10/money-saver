class Budget {
  final String id;
  final String categoryId;
  final double limit;
  final int year;
  final int month;

  const Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.year,
    required this.month,
  });
}
