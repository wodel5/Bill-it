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
      onSubmit: (expense) async {
        final provider = Provider.of<ExpenseProvider>(context, listen: false);
        if (provider.groupFund != null &&
            expense.amount > provider.groupFundRemaining) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Theme.of(ctx).colorScheme.secondary, size: 24),
                  const SizedBox(width: 8),
                  const Text('超出余额', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Text(
                '该笔消费 ¥${expense.amount.toStringAsFixed(2)} 超出当前余额 ¥${provider.groupFundRemaining.toStringAsFixed(2)}，是否继续添加？',
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.12),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide.none,
                        ),
                        child: const Text('取消', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).primaryColor,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('继续添加',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          if (confirm != true || !context.mounted) return;
        }
        provider.addExpense(expense);
        Navigator.pop(context);
      },
    ),
  );
}
