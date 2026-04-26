import 'package:flutter/material.dart';
import 'colors.dart';

class SpendingCategory {
  final String label;
  final int amount;
  final double percentage;
  final Color color;
  const SpendingCategory({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class TopMerchant {
  final String name;
  final int amount;
  const TopMerchant({required this.name, required this.amount});
}

const kDemoTotalSpend = 2847;

const kDemoSpendingCategories = [
  SpendingCategory(label: 'Groceries',      amount: 612, percentage: 0.215, color: kGreen),
  SpendingCategory(label: 'Shopping',       amount: 426, percentage: 0.150, color: Color(0xFFEC4899)),
  SpendingCategory(label: 'Eating Out',     amount: 498, percentage: 0.175, color: kAmber),
  SpendingCategory(label: 'Transportation', amount: 387, percentage: 0.136, color: kBlue),
  SpendingCategory(label: 'Essentials',     amount: 341, percentage: 0.120, color: kTeal),
  SpendingCategory(label: 'Entertainment',  amount: 284, percentage: 0.100, color: Color(0xFF8B5CF6)),
  SpendingCategory(label: 'Other',          amount: 299, percentage: 0.105, color: kTextMuted),
];

const kDemoTopMerchants = [
  TopMerchant(name: "Trader Joe's", amount: 214),
  TopMerchant(name: 'Uber',         amount: 187),
  TopMerchant(name: "McDonald's",   amount: 143),
  TopMerchant(name: 'Amazon',       amount: 126),
  TopMerchant(name: 'CVS Pharmacy', amount: 98),
];
