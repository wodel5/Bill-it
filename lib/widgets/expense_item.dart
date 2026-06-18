import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data_models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';

class ExpenseItem extends StatelessWidget {
  final Expense expense;
  const ExpenseItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (expense.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 16),
                  ),
                Expanded(
                  child: Text(
                    expense.purpose,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '¥${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: expense.isDeleted
                        ? Colors.red
                        : expense.isBilled
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.secondary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  DateFormat('MM-dd').format(expense.date),
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                if (expense.fromPerson != '-') ...[
                  const SizedBox(width: 6),
                  Text(
                    expense.fromPerson,
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (expense.categoryId != null)
                  Builder(
                    builder: (context) {
                      final cat = Provider.of<CategoryProvider>(context)
                          .getById(expense.categoryId);
                      if (cat == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 12, color: cat.color),
                            const SizedBox(width: 3),
                            Text(
                              cat.name,
                              style: TextStyle(
                                  color: cat.color, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: expense.isDeleted
                      ? null
                      : () => Provider.of<ExpenseProvider>(
                            context,
                            listen: false,
                          ).toggleStatus(expense.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: expense.isDeleted
                          ? Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.15)
                          : expense.isBilled
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.15)
                              : Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      expense.isDeleted
                          ? '已删除'
                          : expense.isBilled
                              ? '已报账'
                              : '未报账',
                      style: TextStyle(
                        color: expense.isDeleted
                            ? Theme.of(context).colorScheme.secondary
                            : expense.isBilled
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
