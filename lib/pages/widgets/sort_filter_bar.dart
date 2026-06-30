import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../expense_page.dart';

class SortFilterBar extends StatelessWidget {
  final SortMode sortMode;
  final String? filterCategoryId;
  final String? filterPerson;
  final bool isDropdownOpen;
  final List<ExpenseCategory> categories;
  final List<String> persons;
  final ValueChanged<SortMode> onSortChanged;
  final VoidCallback onFilterAllCleared;
  final ValueChanged<String?> onFilterCategoryToggled;
  final ValueChanged<String?> onFilterPersonToggled;
  final VoidCallback onDropdownOpened;
  final VoidCallback onDropdownCanceled;

  const SortFilterBar({
    super.key,
    required this.sortMode,
    required this.filterCategoryId,
    required this.filterPerson,
    required this.isDropdownOpen,
    required this.categories,
    required this.persons,
    required this.onSortChanged,
    required this.onFilterAllCleared,
    required this.onFilterCategoryToggled,
    required this.onFilterPersonToggled,
    required this.onDropdownOpened,
    required this.onDropdownCanceled,
  });

  static String sortLabel(SortMode m) {
    switch (m) {
      case SortMode.newest:
        return '最近添加';
      case SortMode.oldest:
        return '最早添加';
      case SortMode.amountHigh:
        return '金额高→低';
      case SortMode.amountLow:
        return '金额低→高';
      case SortMode.purposeAsc:
        return '用途 A→Z';
      case SortMode.purposeDesc:
        return '用途 Z→A';
    }
  }

  static Widget miniChip(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? c : c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? c : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : c,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return PopupMenuButton<SortMode>(
      offset: const Offset(0, 6),
      position: PopupMenuPosition.under,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      constraints: const BoxConstraints(minWidth: 120),
      onOpened: () => onDropdownOpened(),
      onCanceled: () => onDropdownCanceled(),
      onSelected: (v) => onSortChanged(v),
      itemBuilder: (context) => SortMode.values.map((m) {
        final selected = m == sortMode;
        return PopupMenuItem<SortMode>(
          value: m,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sortLabel(m),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sortLabel(sortMode),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isDropdownOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 18,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          children: [
            _buildSortDropdown(context),
            const SizedBox(width: 6),
            Container(
              width: 1,
              height: 16,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    miniChip(
                      context,
                      '全部',
                      filterCategoryId == null && filterPerson == null,
                      onFilterAllCleared,
                    ),
                    for (final cat in categories)
                      miniChip(
                        context,
                        cat.name,
                        filterCategoryId == cat.id,
                        () => onFilterCategoryToggled(
                          filterCategoryId == cat.id ? null : cat.id,
                        ),
                        color: cat.color,
                      ),
                    if (persons.isNotEmpty) ...[
                      const SizedBox(width: 2),
                      Container(
                        width: 1,
                        height: 16,
                        color: Theme.of(context).dividerColor,
                      ),
                      const SizedBox(width: 6),
                      for (final p in persons)
                        miniChip(
                          context,
                          p,
                          filterPerson == p,
                          () => onFilterPersonToggled(
                            filterPerson == p ? null : p,
                          ),
                        ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
