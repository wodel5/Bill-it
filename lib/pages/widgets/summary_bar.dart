import 'package:flutter/material.dart';
import '../../data_models/expense.dart';

class GlassSummaryBar extends StatelessWidget {
  final List<Expense> allExpenses;
  final String? filterCategoryId;
  final String? filterPerson;
  final int summaryFilter;
  final VoidCallback onTotalTap;
  final VoidCallback onBilledTap;
  final VoidCallback onUnbilledTap;

  const GlassSummaryBar({
    super.key,
    required this.allExpenses,
    required this.filterCategoryId,
    required this.filterPerson,
    required this.summaryFilter,
    required this.onTotalTap,
    required this.onBilledTap,
    required this.onUnbilledTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = allExpenses.where((e) {
      if (filterCategoryId != null && e.categoryId != filterCategoryId) {
        return false;
      }
      if (filterPerson != null && e.fromPerson != filterPerson) {
        return false;
      }
      return true;
    }).toList();
    final total = base.fold<double>(0, (s, e) => s + e.amount);
    final unclaimed =
        base.where((e) => !e.isBilled).fold<double>(0, (s, e) => s + e.amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        children: [
          _summaryTab(
            context,
            '总金额',
            total,
            summaryFilter == -1,
            onTotalTap,
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
          _summaryTab(
            context,
            '已报账',
            total - unclaimed,
            summaryFilter == 1,
            onBilledTap,
            labelColor: Theme.of(context).primaryColor,
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
          _summaryTab(
            context,
            '未报账',
            unclaimed,
            summaryFilter == 0,
            onUnbilledTap,
            labelColor: Theme.of(context).colorScheme.secondary,
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  Widget _summaryTab(
    BuildContext context,
    String label,
    double amount,
    bool active,
    VoidCallback onTap, {
    Color? labelColor,
    Color? pillColor,
  }) {
    final c = active
        ? (labelColor ??
              Theme.of(context).textTheme.bodyLarge?.color ??
              Colors.black)
        : Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.5) ??
              Colors.grey;
    String amountStr;
    if (amount >= 100000000) {
      amountStr = '¥${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      amountStr = '¥${(amount / 10000).toStringAsFixed(2)}万';
    } else {
      amountStr = '¥${amount.toStringAsFixed(2)}';
    }
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: active ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: Text(
                  amountStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
