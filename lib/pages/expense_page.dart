import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/expense_item.dart';
import '../dialogs/add_expense_sheet.dart';
import '../dialogs/edit_expense_dialog.dart' show showEditExpenseSheet;
import '../dialogs/trash_sheet.dart';
import '../dialogs/updates.dart';
import '../services/update_service.dart';
import 'widgets/search_add_bar.dart';
import 'widgets/sort_filter_bar.dart';
import 'widgets/multi_select_bar.dart';
import 'widgets/summary_bar.dart';
import 'widgets/expense_actions.dart';
import 'widgets/empty_state.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

enum SortMode { newest, oldest, amountHigh, amountLow, purposeAsc, purposeDesc }

const _pinyinMap = {
  '餐': 'can',
  '饮': 'yin',
  '交': 'jiao',
  '通': 'tong',
  '办': 'ban',
  '公': 'gong',
  '住': 'zhu',
  '宿': 'su',
  '车': 'che',
  '费': 'fei',
  '差': 'chai',
  '旅': 'lv',
  '会': 'hui',
  '议': 'yi',
  '打': 'da',
  '印': 'yin',
  '文': 'wen',
  '具': 'ju',
  '电': 'dian',
  '话': 'hua',
  '网': 'wang',
  '邮': 'you',
  '递': 'di',
  '礼': 'li',
  '品': 'pin',
  '招': 'zhao',
  '待': 'dai',
  '报': 'bao',
  '销': 'xiao',
  '材': 'cai',
  '料': 'liao',
  '设': 'she',
  '备': 'bei',
  '维': 'wei',
  '修': 'xiu',
  '运': 'yun',
  '输': 'shu',
  '培': 'pei',
  '训': 'xun',
  '书': 'shu',
  '籍': 'ji',
  '水': 'shui',
  '租': 'zu',
  '金': 'jin',
  '物': 'wu',
  '业': 'ye',
  '保': 'bao',
  '安': 'an',
  '清': 'qing',
  '洁': 'jie',
  '软': 'ruan',
  '件': 'jian',
  '硬': 'ying',
  '广': 'guang',
  '告': 'gao',
  '推': 'tui',
  '咨': 'zi',
  '询': 'xun',
  '服': 'fu',
  '务': 'wu',
  '其': 'qi',
  '他': 'ta',
};

String _toPinyin(String s) {
  final b = StringBuffer();
  for (final ch in s.characters) {
    b.write(_pinyinMap[ch] ?? ch);
  }
  return b.toString();
}

class _ExpensePageState extends State<ExpensePage> {
  bool _isLoading = true;
  GlobalKey<AnimatedListState> _listKey = GlobalKey();
  List<Expense> _currentExpenses = [];
  ExpenseProvider? _provider;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchFocused = false;
  String _searchKeyword = '';
  SortMode _sortMode = SortMode.newest;
  bool? _filterStatus;
  String? _filterCategoryId;
  String? _filterPerson;
  int _summaryFilter;
  bool _isDropdownOpen = false;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  _ExpensePageState() : _summaryFilter = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.loadData();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentExpenses = _applyAll(provider.sortedExpenses);
      });
    }
    _provider = provider;
    _provider?.addListener(_onExpensesChanged);
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
    _silentCheckUpdate();
  }

  Future<void> _silentCheckUpdate() async {
    await UpdateService.silentCheck();
    if (!mounted) return;
    if (UpdateService.hasNewVersion.value) {
      final skipped = await UpdateService.getSkippedVersion();
      if (skipped != UpdateService.latestVersion) {
        showUpdateDialog(context);
      }
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onExpensesChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _enterMultiSelect(String id) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedIds.clear();
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _currentExpenses.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_currentExpenses.map((e) => e.id));
      }
    });
  }

  void _batchToggleBilled(bool billed) {
    for (final id in _selectedIds) {
      final expense = _currentExpenses.firstWhere((e) => e.id == id);
      if (expense.isBilled != billed) {
        _provider!.toggleStatus(id);
      }
    }
    _exitMultiSelect();
  }

  void _batchDelete() {
    for (final id in _selectedIds) {
      _provider!.moveToTrash(id);
    }
    _exitMultiSelect();
  }

  void _onExpensesChanged() {
    if (_provider == null) return;
    final newExpenses = _applyAll(_provider!.sortedExpenses);

    if (_isFiltered) {
      setState(() => _currentExpenses = newExpenses);
      return;
    }

    if (newExpenses.length < _currentExpenses.length) {
      Expense? removed;
      for (final e in _currentExpenses) {
        if (!newExpenses.any((x) => x.id == e.id)) {
          removed = e;
          break;
        }
      }
      if (removed != null) {
        final idx = _currentExpenses.indexWhere((e) => e.id == removed!.id);
        if (idx != -1) {
          _listKey.currentState?.removeItem(
            idx,
            (context, animation) => SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: IgnorePointer(child: ExpenseItem(expense: removed!)),
              ),
            ),
            duration: const Duration(milliseconds: 150),
          );
        }
      }
    }

    if (newExpenses.length > _currentExpenses.length) {
      for (int i = 0; i < newExpenses.length; i++) {
        if (i >= _currentExpenses.length ||
            newExpenses[i].id != _currentExpenses[i].id) {
          _listKey.currentState?.insertItem(i);
          break;
        }
      }
    }

    if (newExpenses.length == _currentExpenses.length) {
      for (int i = 0; i < newExpenses.length; i++) {
        if (newExpenses[i].id != _currentExpenses[i].id) {
          _listKey = GlobalKey();
          break;
        }
      }
    }

    setState(() => _currentExpenses = newExpenses);
  }

  bool get _isFiltered =>
      _searchKeyword.isNotEmpty ||
      _filterStatus != null ||
      _filterCategoryId != null ||
      _filterPerson != null;

  List<Expense> _applyAll(List<Expense> expenses) {
    var list = _applySearch(expenses);
    list = _applyFilters(list);
    return _applySort(list);
  }

  List<Expense> _applySearch(List<Expense> expenses) {
    if (_searchKeyword.isEmpty) return List.from(expenses);
    final kw = _searchKeyword.toLowerCase();
    return expenses.where((e) {
      if (e.purpose.toLowerCase().contains(kw)) return true;
      if (e.fromPerson.toLowerCase().contains(kw)) return true;
      return false;
    }).toList();
  }

  List<Expense> _applyFilters(List<Expense> expenses) {
    return expenses.where((e) {
      if (_filterStatus != null && e.isBilled != _filterStatus) return false;
      if (_filterCategoryId != null && e.categoryId != _filterCategoryId) {
        return false;
      }
      if (_filterPerson != null && e.fromPerson != _filterPerson) return false;
      return true;
    }).toList();
  }

  List<Expense> _applySort(List<Expense> expenses) {
    final pinned = expenses.where((e) => e.isPinned).toList();
    final unpinned = expenses.where((e) => !e.isPinned).toList();

    void sortGroup(List<Expense> list) {
      switch (_sortMode) {
        case SortMode.newest:
          list.sort((a, b) => b.date.compareTo(a.date));
        case SortMode.oldest:
          list.sort((a, b) => a.date.compareTo(b.date));
        case SortMode.amountHigh:
          list.sort((a, b) => b.amount.compareTo(a.amount));
        case SortMode.amountLow:
          list.sort((a, b) => a.amount.compareTo(b.amount));
        case SortMode.purposeAsc:
          list.sort(
            (a, b) => _toPinyin(a.purpose).compareTo(_toPinyin(b.purpose)),
          );
        case SortMode.purposeDesc:
          list.sort(
            (a, b) => _toPinyin(b.purpose).compareTo(_toPinyin(a.purpose)),
          );
      }
    }

    sortGroup(pinned);
    sortGroup(unpinned);
    return [...pinned, ...unpinned];
  }

  int get _totalCount => _provider?.sortedExpenses.length ?? 0;

  void _openTrash() => showTrashSheet(context);
  void _openEdit(Expense e) => showEditExpenseSheet(context, e);

  IconData _themeIcon(BuildContext context) {
    switch (Provider.of<ThemeProvider>(context).themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '¥${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(2)}万';
    } else {
      return '¥${amount.toStringAsFixed(2)}';
    }
  }

  void _showSetGroupFundDialog() {
    final controller = TextEditingController(
      text: _provider?.groupFund?.toStringAsFixed(2) ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet,
                color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            const Text('设置余额', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                hintText: '请输入组里总资金',
                prefixText: '¥ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_provider?.groupFund != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _provider!.clearGroupFund();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.withValues(alpha: 0.12),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide.none,
                      ),
                      child: const Text('清除', style: TextStyle(color: Colors.red, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      final value = double.tryParse(controller.text);
                      if (value != null) {
                        _provider!.setGroupFund(value);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('确定', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isMultiSelectMode) {
          _exitMultiSelect();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '报账了吗',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$_totalCount条',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          ValueListenableBuilder<double>(
            valueListenable: UpdateService.downloadProgress,
            builder: (_, progress, __) {
              if (UpdateService.isDownloading) {
                return GestureDetector(
                  onTap: () => showDownloadDialog(context),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.5,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                        ),
                        Text(
                          '${(progress * 100).toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ValueListenableBuilder<bool>(
                valueListenable: UpdateService.hasNewVersion,
                builder: (_, hasUpdate, __) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.loop),
                      color: Theme.of(context).primaryColor,
                      iconSize: 22,
                      onPressed: () => showUpdateDialog(context),
                    ),
                    if (hasUpdate)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Theme.of(context).primaryColor,
            iconSize: 22,
            onPressed: _openTrash,
          ),
          IconButton(
            icon: Icon(
              _themeIcon(context),
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).cycleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SearchAddBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchFocused: _searchFocused,
              onSearchChanged: (v) => setState(() {
                _searchKeyword = v;
                _currentExpenses = _applyAll(_provider!.sortedExpenses);
              }),
              onAddPressed: () => showAddExpenseSheet(context),
              groupFund: _provider?.groupFund,
              groupFundRemaining: _provider?.groupFundRemaining ?? 0,
              onGroupFundTap: _showSetGroupFundDialog,
              formatAmount: _formatAmount,
            ),
            SortFilterBar(
              sortMode: _sortMode,
              filterCategoryId: _filterCategoryId,
              filterPerson: _filterPerson,
              isDropdownOpen: _isDropdownOpen,
              categories: Provider.of<CategoryProvider>(context).categories,
              persons: <String>{
                for (final e in _provider?.sortedExpenses ?? <Expense>[])
                  if (e.fromPerson != '-' && e.fromPerson.isNotEmpty) e.fromPerson,
              }.toList(),
              onSortChanged: (v) => setState(() {
                _sortMode = v;
                _isDropdownOpen = false;
                _currentExpenses = _applyAll(_provider!.sortedExpenses);
              }),
              onFilterAllCleared: () => setState(() {
                _filterStatus = null;
                _filterCategoryId = null;
                _filterPerson = null;
                _summaryFilter = -1;
                _currentExpenses = _applyAll(_provider!.sortedExpenses);
              }),
              onFilterCategoryToggled: (catId) => setState(() {
                _filterCategoryId = catId;
                _currentExpenses = _applyAll(_provider!.sortedExpenses);
              }),
              onFilterPersonToggled: (person) => setState(() {
                _filterPerson = person;
                _currentExpenses = _applyAll(_provider!.sortedExpenses);
              }),
              onDropdownOpened: () => setState(() => _isDropdownOpen = true),
              onDropdownCanceled: () => setState(() => _isDropdownOpen = false),
            ),
            Expanded(
              child: SlidableAutoCloseBehavior(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _searchFocusNode.unfocus();
                    if (_isMultiSelectMode) _exitMultiSelect();
                  },
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : _currentExpenses.isEmpty
                      ? EmptyState(searchKeyword: _searchKeyword)
                      : _isFiltered
                      ? ListView.builder(
                          itemCount: _currentExpenses.length,
                          itemBuilder: (_, i) =>
                              _buildItem(_currentExpenses[i]),
                        )
                      : AnimatedList(
                          key: _listKey,
                          initialItemCount: _currentExpenses.length,
                          itemBuilder: (_, i, a) =>
                              _buildAnimatedItem(_currentExpenses[i], i, a),
                        ),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => SizeTransition(
                sizeFactor: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _isMultiSelectMode
                  ? MultiSelectBar(
                      key: const ValueKey('multi'),
                      selectedIds: _selectedIds,
                      currentExpenses: _currentExpenses,
                      onExit: _exitMultiSelect,
                      onSelectAll: _selectAll,
                      onBatchToggleBilled: _batchToggleBilled,
                      onBatchDelete: _batchDelete,
                    )
                  : GlassSummaryBar(
                      key: const ValueKey('summary'),
                      allExpenses: _provider?.sortedExpenses ?? [],
                      filterCategoryId: _filterCategoryId,
                      filterPerson: _filterPerson,
                      summaryFilter: _summaryFilter,
                      onTotalTap: () => setState(() {
                        _summaryFilter = -1;
                        _filterStatus = null;
                        _currentExpenses = _applyAll(_provider!.sortedExpenses);
                      }),
                      onBilledTap: () => setState(() {
                        _summaryFilter = 1;
                        _filterStatus = true;
                        _currentExpenses = _applyAll(_provider!.sortedExpenses);
                      }),
                      onUnbilledTap: () => setState(() {
                        _summaryFilter = 0;
                        _filterStatus = false;
                        _currentExpenses = _applyAll(_provider!.sortedExpenses);
                      }),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildItem(Expense expense) {
    final isSelected = _selectedIds.contains(expense.id);
    return GestureDetector(
      onLongPress: () {
        if (!_isMultiSelectMode) {
          _enterMultiSelect(expense.id);
        }
      },
      onTap: () {
        if (_isMultiSelectMode) {
          _toggleSelect(expense.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isMultiSelectMode
              ? (isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.08)
                  : null)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isMultiSelectMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelect(expense.id),
                      activeColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
            ),
            Expanded(
              child: _isMultiSelectMode
                  ? ExpenseItem(expense: expense)
                  : Slidable(
                      key: Key(expense.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.6,
                        children: [
                          Builder(builder: (c) => Expanded(child: buildPinAction(expense, c))),
                          const SizedBox(width: 5),
                          Builder(
                            builder: (c) => Expanded(child: buildEditAction(expense, c, () => _openEdit(expense))),
                          ),
                          const SizedBox(width: 5),
                          Builder(
                            builder: (c) => Expanded(child: buildTrashAction(expense, c)),
                          ),
                        ],
                      ),
                      child: ExpenseItem(expense: expense),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(Expense e, int i, Animation<double> a) {
    return SizeTransition(
      sizeFactor: a,
      child: FadeTransition(opacity: a, child: _buildItem(e)),
    );
  }
}
