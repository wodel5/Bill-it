import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../data_models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/expense_item.dart';
import '../popup/add_expense_sheet.dart';
import '../popup/edit_expense_dialog.dart' show showEditExpenseSheet;
import '../popup/trash_sheet.dart';
import '../popup/updates.dart';
import '../services/update_service.dart';

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

  String _sortLabel(SortMode m) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            _searchAddBar(),
            _sortFilterBar(),
            Expanded(
              child: SlidableAutoCloseBehavior(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _searchFocusNode.unfocus(),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      : _currentExpenses.isEmpty
                      ? _buildEmptyState()
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
            _glassSummaryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _searchKeyword.isNotEmpty ? '无匹配结果' : '暂无记录',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchAddBar() {
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
                  color: _searchFocused
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: _searchFocused ? 1.5 : 1,
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
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '搜索...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() {
                        _searchKeyword = v;
                        _currentExpenses = _applyAll(_provider!.sortedExpenses);
                      }),
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
              onPressed: () => showAddExpenseSheet(context),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showSetGroupFundDialog,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              alignment: Alignment.center,
              child: _provider?.groupFund != null
                  ? Text(
                      '余额 ${_formatAmount(_provider!.groupFundRemaining)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _provider!.groupFundRemaining < 0
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

  Widget _sortFilterBar() {
    final catProvider = Provider.of<CategoryProvider>(context);
    final categories = catProvider.categories;
    final persons = <String>{
      for (final e in _provider?.sortedExpenses ?? <Expense>[])
        if (e.fromPerson != '-' && e.fromPerson.isNotEmpty) e.fromPerson,
    }.toList();

    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        child: Row(
          children: [
            _buildSortDropdown(),
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
                    _miniChip(
                      '全部',
                      _filterCategoryId == null && _filterPerson == null,
                      () => setState(() {
                        _filterStatus = null;
                        _filterCategoryId = null;
                        _filterPerson = null;
                        _summaryFilter = -1;
                        _currentExpenses = _applyAll(_provider!.sortedExpenses);
                      }),
                    ),
                    for (final cat in categories)
                      _miniChip(
                        cat.name,
                        _filterCategoryId == cat.id,
                        () => setState(() {
                          _filterCategoryId = _filterCategoryId == cat.id
                              ? null
                              : cat.id;
                          _currentExpenses = _applyAll(
                            _provider!.sortedExpenses,
                          );
                        }),
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
                        _miniChip(
                          p,
                          _filterPerson == p,
                          () => setState(() {
                            _filterPerson = _filterPerson == p ? null : p;
                            _currentExpenses = _applyAll(
                              _provider!.sortedExpenses,
                            );
                          }),
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

  Widget _miniChip(
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

  Widget _buildSortDropdown() {
    return PopupMenuButton<SortMode>(
      offset: const Offset(0, 6),
      position: PopupMenuPosition.under,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      constraints: const BoxConstraints(minWidth: 120),
      onOpened: () => setState(() => _isDropdownOpen = true),
      onCanceled: () => setState(() => _isDropdownOpen = false),
      onSelected: (v) {
        setState(() {
          _sortMode = v;
          _isDropdownOpen = false;
          _currentExpenses = _applyAll(_provider!.sortedExpenses);
        });
      },
      itemBuilder: (context) => SortMode.values.map((m) {
        final selected = m == _sortMode;
        return PopupMenuItem<SortMode>(
          value: m,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _sortLabel(m),
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
              _sortLabel(_sortMode),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isDropdownOpen
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

  Widget _glassSummaryBar() {
    final all = _provider?.sortedExpenses ?? [];
    final base = all.where((e) {
      if (_filterCategoryId != null && e.categoryId != _filterCategoryId) {
        return false;
      }
      if (_filterPerson != null && e.fromPerson != _filterPerson) {
        return false;
      }
      return true;
    }).toList();
    final total = base.fold<double>(0, (s, e) => s + e.amount);
    final unclaimed = base
        .where((e) => !e.isBilled)
        .fold<double>(0, (s, e) => s + e.amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Row(
        children: [
          _summaryTab(
            '总金额',
            total,
            _summaryFilter == -1,
            () => setState(() {
              _summaryFilter = -1;
              _filterStatus = null;
              _currentExpenses = _applyAll(_provider!.sortedExpenses);
            }),
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
          _summaryTab(
            '已报账',
            total - unclaimed,
            _summaryFilter == 1,
            () => setState(() {
              _summaryFilter = 1;
              _filterStatus = true;
              _currentExpenses = _applyAll(_provider!.sortedExpenses);
            }),
            labelColor: Theme.of(context).primaryColor,
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
          _summaryTab(
            '未报账',
            unclaimed,
            _summaryFilter == 0,
            () => setState(() {
              _summaryFilter = 0;
              _filterStatus = false;
              _currentExpenses = _applyAll(_provider!.sortedExpenses);
            }),
            labelColor: Theme.of(context).colorScheme.secondary,
            pillColor: const Color(0xFFF3F3F3).withValues(alpha: 0.25),
          ),
        ],
      ),
    );
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

  Widget _summaryTab(
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

  Widget _buildItem(Expense expense) {
    return Slidable(
      key: Key(expense.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.6,
        children: [
          Builder(builder: (c) => Expanded(child: _buildPinAction(expense, c))),
          const SizedBox(width: 5),
          Builder(
            builder: (c) => Expanded(child: _buildEditAction(expense, c)),
          ),
          const SizedBox(width: 5),
          Builder(
            builder: (c) => Expanded(child: _buildTrashAction(expense, c)),
          ),
        ],
      ),
      child: ExpenseItem(expense: expense),
    );
  }

  Widget _buildAnimatedItem(Expense e, int i, Animation<double> a) {
    return SizeTransition(
      sizeFactor: a,
      child: FadeTransition(opacity: a, child: _buildItem(e)),
    );
  }

  Widget _buildEditAction(Expense expense, BuildContext context) =>
      GestureDetector(
        onTap: () {
          _openEdit(expense);
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

  Widget _buildPinAction(Expense expense, BuildContext context) =>
      GestureDetector(
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

  Widget _buildTrashAction(Expense expense, BuildContext context) =>
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
              SizedBox(height: 4),
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
}
