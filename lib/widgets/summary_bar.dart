//底部总计栏

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder:
          (context, provider, _) => Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  flex: 1,
                  child: _summaryItem(context, '总金额', provider.totalAmount),
                ),
                Expanded(
                  flex: 1,
                  child: _summaryItem(
                    context,
                    '未报账',
                    provider.unclaimedAmount,
                    isDanger: true,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    double value, {
    bool isDanger = false,
  }) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
        fontSize: 14,
      )),
      Text(
        '¥${value.toStringAsFixed(2)}',
        style: TextStyle(
          color:
              isDanger
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
