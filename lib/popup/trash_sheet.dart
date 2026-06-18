import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../data_models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_item.dart';

class TrashSheet extends StatefulWidget {
  const TrashSheet({super.key});

  @override
  State<TrashSheet> createState() => _TrashSheetState();
}

class _TrashSheetState extends State<TrashSheet> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<Expense> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(
      Provider.of<ExpenseProvider>(context, listen: false).trashExpenses,
    );
  }

  void _restore(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    Provider.of<ExpenseProvider>(context, listen: false).restoreExpense(id);
    _listKey.currentState?.removeItem(
      idx,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: IgnorePointer(
            child: ExpenseItem(expense: item),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 150),
    );
    setState(() => _items.removeAt(idx));
  }

  void _permanentlyDelete(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    Provider.of<ExpenseProvider>(context, listen: false).permanentlyDelete(id);
    _listKey.currentState?.removeItem(
      idx,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: IgnorePointer(
            child: ExpenseItem(expense: item),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 150),
    );
    setState(() => _items.removeAt(idx));
  }

  Widget _buildAnimatedItem(
      Expense expense, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: _buildItem(expense),
      ),
    );
  }

  Widget _buildItem(Expense expense) {
    return Slidable(
      key: Key(expense.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.4,
        children: [
          Builder(
            builder: (context) =>
                Expanded(child: _buildRestoreAction(expense, context)),
          ),
          const SizedBox(width: 5),
          Builder(
            builder: (context) => Expanded(
                child: _buildPermanentDeleteAction(expense, context)),
          ),
        ],
      ),
      child: ExpenseItem(expense: expense),
    );
  }

  Widget _buildRestoreAction(Expense expense, BuildContext context) =>
      GestureDetector(
        onTap: () {
          _restore(expense.id);
          Slidable.of(context)?.close();
        },
        child: Card(
          margin: const EdgeInsets.all(5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restore_from_trash, color: Colors.green, size: 24),
              SizedBox(height: 4),
              Text('恢复', style: TextStyle(fontSize: 14, color: Colors.green)),
            ],
          ),
        ),
      );

  Widget _buildPermanentDeleteAction(Expense expense, BuildContext context) =>
      GestureDetector(
        onTap: () {
          _permanentlyDelete(expense.id);
          Slidable.of(context)?.close();
        },
        child: Card(
          margin: const EdgeInsets.all(5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.red, size: 24),
              SizedBox(height: 4),
              Text('彻底删除',
                  style: TextStyle(fontSize: 14, color: Colors.red)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 16),
            const Text(
              '回收站',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${_items.length} 条',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 48,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('回收站为空',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.6),
                              fontSize: 16)),
                    ],
                  ),
                )
              : AnimatedList(
                  key: _listKey,
                  initialItemCount: _items.length,
                  itemBuilder: (context, index, animation) =>
                      _buildAnimatedItem(_items[index], index, animation),
                ),
        ),
      ],
    );
  }
}

Future<void> showTrashSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: const TrashSheet(),
    ),
  );
}
