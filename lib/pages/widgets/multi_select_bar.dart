import 'package:flutter/material.dart';
import '../../models/expense.dart';

class MultiSelectBar extends StatelessWidget {
  final Set<String> selectedIds;
  final List<Expense> currentExpenses;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;
  final ValueChanged<bool> onBatchToggleBilled;
  final VoidCallback onBatchDelete;

  const MultiSelectBar({
    super.key,
    required this.selectedIds,
    required this.currentExpenses,
    required this.onExit,
    required this.onSelectAll,
    required this.onBatchToggleBilled,
    required this.onBatchDelete,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedIds.length == currentExpenses.length;
    final hasBilled = selectedIds.any(
      (id) => currentExpenses.firstWhere((e) => e.id == id).isBilled,
    );
    final hasUnbilled = selectedIds.any(
      (id) => !currentExpenses.firstWhere((e) => e.id == id).isBilled,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onExit,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '已选 ${selectedIds.length} 条',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSelectAll,
                child: Text(
                  allSelected ? '取消全选' : '全选',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (hasUnbilled)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onBatchToggleBilled(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.12),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      '标记已报账',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              if (hasUnbilled && hasBilled) const SizedBox(width: 8),
              if (hasBilled)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onBatchToggleBilled(false),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.12),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      '标记未报账',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              if (!hasBilled && !hasUnbilled) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onBatchToggleBilled(true),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.12),
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide.none,
                    ),
                    child: Text(
                      '标记已报账',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onBatchDelete,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.12),
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide.none,
                  ),
                  child: Text(
                    '删除',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
