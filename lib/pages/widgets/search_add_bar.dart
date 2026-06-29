import 'package:flutter/material.dart';

class SearchAddBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final bool searchFocused;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddPressed;
  final double? groupFund;
  final double groupFundRemaining;
  final VoidCallback onGroupFundTap;
  final String Function(double) formatAmount;

  const SearchAddBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchFocused,
    required this.onSearchChanged,
    required this.onAddPressed,
    required this.groupFund,
    required this.groupFundRemaining,
    required this.onGroupFundTap,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: searchFocused
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: searchFocused ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      focusNode: searchFocusNode,
                      controller: searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '搜索...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 39,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onAddPressed,
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onGroupFundTap,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              alignment: Alignment.center,
              child: groupFund != null
                  ? Text(
                      '余额 ${formatAmount(groupFundRemaining)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: groupFundRemaining < 0
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                      ),
                    )
                  : Text(
                      '设置余额',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
