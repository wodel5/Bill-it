import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'expense_form.dart';

Future<void> showEditExpenseSheet(BuildContext context, Expense expense) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => ExpenseFormSheet(
      title: '编辑记录',
      initialExpense: expense,
      submitLabel: '更新记录',
      showCancel: true,
      onSubmit: (updated) {
        Provider.of<ExpenseProvider>(context, listen: false)
            .updateExpense(expense.id, updated);
        Navigator.pop(context);
      },
    ),
  );
}
