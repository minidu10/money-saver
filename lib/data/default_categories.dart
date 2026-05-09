import 'package:flutter/material.dart';

import 'models/category.dart';
import 'models/transaction.dart';

const List<AppCategory> defaultCategories = [
  // Income
  AppCategory(
    id: 'salary',
    name: 'Salary',
    colorValue: 0xFF2E7D5B,
    iconCodePoint: 0xe227, // attach_money
    type: TransactionType.income,
  ),
  AppCategory(
    id: 'gift',
    name: 'Gift',
    colorValue: 0xFFD81B60,
    iconCodePoint: 0xe8f6, // card_giftcard
    type: TransactionType.income,
  ),
  AppCategory(
    id: 'other_income',
    name: 'Other income',
    colorValue: 0xFF6D4C41,
    iconCodePoint: 0xe1db, // payments
    type: TransactionType.income,
  ),

  // Expense
  AppCategory(
    id: 'food',
    name: 'Food',
    colorValue: 0xFFFF7043,
    iconCodePoint: 0xe25a, // restaurant
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'transport',
    name: 'Transport',
    colorValue: 0xFF1E88E5,
    iconCodePoint: 0xe1d5, // directions_bus
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'shopping',
    name: 'Shopping',
    colorValue: 0xFFAB47BC,
    iconCodePoint: 0xe8cc, // shopping_bag
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'bills',
    name: 'Bills',
    colorValue: 0xFFEF5350,
    iconCodePoint: 0xe9f4, // receipt_long
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'health',
    name: 'Health',
    colorValue: 0xFF26A69A,
    iconCodePoint: 0xe305, // local_hospital
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'entertainment',
    name: 'Entertainment',
    colorValue: 0xFF7E57C2,
    iconCodePoint: 0xe02c, // movie
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'education',
    name: 'Education',
    colorValue: 0xFF42A5F5,
    iconCodePoint: 0xe80c, // school
    type: TransactionType.expense,
  ),
  AppCategory(
    id: 'other_expense',
    name: 'Other',
    colorValue: 0xFF78909C,
    iconCodePoint: 0xe148, // category
    type: TransactionType.expense,
  ),
];

AppCategory categoryById(String id) {
  return defaultCategories.firstWhere(
    (c) => c.id == id,
    orElse: () => const AppCategory(
      id: 'unknown',
      name: 'Unknown',
      colorValue: 0xFF9E9E9E,
      iconCodePoint: 0xe148,
      type: TransactionType.expense,
    ),
  );
}

extension AppCategoryX on AppCategory {
  Color get color => Color(colorValue);
  IconData get icon =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}
