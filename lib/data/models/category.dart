import 'package:flutter/material.dart';

import 'transaction.dart';

class AppCategory {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final TransactionType type;

  const AppCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.type,
  });
}
