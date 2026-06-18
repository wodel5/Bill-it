import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'expense_form.dart';

Future<void> showAddExpenseSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ExpenseFormSheet(
      title: '添加记录',
      submitLabel: '添加记录',
      onSubmit: (expense) {
        Provider.of<ExpenseProvider>(context, listen: false)
            .addExpense(expense);
        Navigator.pop(context);
      },
    ),
  );
}
