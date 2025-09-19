// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:only_j/main.dart';

void main() {
  group('ExpenseStorage Tests', () {
    test('Save and Load Expenses', () async {
      SharedPreferences.setMockInitialValues({}); // モックの初期化

      final expenses = [
        Expense(id: '1', title: 'Lunch', amount: 12.5, date: DateTime(2025, 9, 1)),
        Expense(id: '2', title: 'Coffee', amount: 3.0, date: DateTime(2025, 9, 2)),
      ];

      await ExpenseStorage.saveExpenses(expenses);
      final loadedExpenses = await ExpenseStorage.loadExpenses();

      expect(loadedExpenses.length, expenses.length);
      expect(loadedExpenses[0].title, expenses[0].title);
      expect(loadedExpenses[1].amount, expenses[1].amount);
    });

    test('Calculate Monthly Expense Total', () {
      final expenses = [
        Expense(id: '1', title: 'Lunch', amount: 12.5, date: DateTime(2025, 9, 1)),
        Expense(id: '2', title: 'Coffee', amount: 3.0, date: DateTime(2025, 9, 2)),
        Expense(id: '3', title: 'Dinner', amount: 20.0, date: DateTime(2025, 8, 31)),
      ];

      final total = calculateMonthlyExpenseTotal(expenses);

      expect(total, 15.5); // 9月分の合計
    });
  });
}
