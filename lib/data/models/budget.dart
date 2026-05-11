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

  String get key => '${year}_${month.toString().padLeft(2, '0')}_$categoryId';

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'limit': limit,
        'year': year,
        'month': month,
      };

  factory Budget.fromMap(String id, Map<String, dynamic> m) => Budget(
        id: id,
        categoryId: m['categoryId'] as String,
        limit: (m['limit'] as num).toDouble(),
        year: m['year'] as int,
        month: m['month'] as int,
      );

  Budget copyWith({double? limit}) => Budget(
        id: id,
        categoryId: categoryId,
        limit: limit ?? this.limit,
        year: year,
        month: month,
      );
}
