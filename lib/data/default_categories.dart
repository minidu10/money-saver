import 'package:flutter/material.dart';

import 'models/category.dart';
import 'models/transaction.dart';

const List<AppCategory> defaultCategories = [
  // Income
  AppCategory(
    id: 'salary',
    name: 'Salary',
    color: Color(0xFF2E7D5B),
    icon: Icons.attach_money,
    type: TransactionType.income,
  ),
  AppCategory(
    id: 'gift',
    name: 'Gift',
    color: Color(0xFFD81B60),
    icon: Icons.card_giftcard,
    type: TransactionType.income,
  ),
  AppCategory(
    id: 'other_income',
    name: 'Other income',
    color: Color(0xFF6D4C41),
    icon: Icons.payments,
    type: TransactionType.income,
  ),

  // Expense
  AppCategory(
    id: 'food',
    name: 'Food',
    color: Color(0xFFFF7043),
    icon: Icons.restaurant,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'transport',
    name: 'Transport',
    color: Color(0xFF1E88E5),
    icon: Icons.directions_bus,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'shopping',
    name: 'Shopping',
    color: Color(0xFFAB47BC),
    icon: Icons.shopping_bag,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'bills',
    name: 'Bills',
    color: Color(0xFFEF5350),
    icon: Icons.receipt_long,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'health',
    name: 'Health',
    color: Color(0xFF26A69A),
    icon: Icons.local_hospital,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'entertainment',
    name: 'Entertainment',
    color: Color(0xFF7E57C2),
    icon: Icons.movie,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'education',
    name: 'Education',
    color: Color(0xFF42A5F5),
    icon: Icons.school,
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'other_expense',
    name: 'Other',
    color: Color(0xFF78909C),
    icon: Icons.category,
    type: TransactionType.expense,
  ),
];

const AppCategory _unknownCategory = AppCategory(
  id: 'unknown',
  name: 'Unknown',
  color: Color(0xFF9E9E9E),
  icon: Icons.category,
  type: TransactionType.expense,
);

AppCategory categoryById(String id) {
  return defaultCategories.firstWhere(
    (c) => c.id == id,
    orElse: () => _unknownCategory,
  );
}
