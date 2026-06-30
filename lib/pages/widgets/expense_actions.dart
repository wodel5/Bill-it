import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

Widget buildPinAction(Expense expense, BuildContext context) => GestureDetector(
  onTap: () {
    Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).togglePin(expense.id);
    Slidable.of(context)?.close();
  },
  child: Card(
    margin: const EdgeInsets.all(5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 2,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          expense.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          color: Theme.of(context).colorScheme.tertiary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          expense.isPinned ? '取消置顶' : '置顶',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    ),
  ),
);

Widget buildEditAction(
  Expense expense,
  BuildContext context,
  VoidCallback onEdit,
) => GestureDetector(
  onTap: () {
    onEdit();
    Slidable.of(context)?.close();
  },
  child: Card(
    margin: const EdgeInsets.all(5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 2,
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit, color: Colors.blue, size: 24),
        SizedBox(height: 4),
        Text('编辑', style: TextStyle(fontSize: 14, color: Colors.blue)),
      ],
    ),
  ),
);

Widget buildTrashAction(Expense expense, BuildContext context) =>
    GestureDetector(
      onTap: () {
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).moveToTrash(expense.id);
        Slidable.of(context)?.close();
      },
      child: Card(
        margin: const EdgeInsets.all(5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              '删除',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
