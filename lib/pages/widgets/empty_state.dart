import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String searchKeyword;

  const EmptyState({super.key, required this.searchKeyword});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            searchKeyword.isNotEmpty ? '无匹配结果' : '暂无记录',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
