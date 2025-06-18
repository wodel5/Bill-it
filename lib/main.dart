import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// 应用入口，使用Provider进行状态管理
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: const MyApp(),
    ),
  );
}

/// 应用根组件，配置主题和本地化
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '报账了吗',
      theme: ThemeData(
        primaryColor: const Color(0xFF07C160), // 主色调 - 微信绿
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFEE0A24), // 强调色 - 警示红
        ),
        fontFamily: 'PingFang SC', // 使用中文常用字体
      ),
      home: const ExpenseTrackerScreen(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate, // 国际化支持
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [const Locale('zh', 'CH'), const Locale('en', 'US')],
    );
  }
}

/// 消费记录数据模型
class Expense {
  final String id; // 唯一标识符
  final double amount; // 金额
  final String purpose; // 用途
  final DateTime date; // 日期
  bool isClaimed; // 报账状态
  bool isPinned; // 置顶状态

  Expense({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.date,
    this.isClaimed = false,
    this.isPinned = false,
  });

  /// 数据序列化方法
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'purpose': purpose,
    'date': date.toIso8601String(),
    'isClaimed': isClaimed,
    'isPinned': isPinned,
  };

  /// 数据反序列化方法
  static Expense fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    amount: json['amount'],
    purpose: json['purpose'],
    date: DateTime.parse(json['date']),
    isClaimed: json['isClaimed'],
    isPinned: json['isPinned'] ?? false,
  );
}

/// 消费记录状态管理 - MVVM架构中的ViewModel
class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  final String _storageKey = 'expenseRecords'; // 本地存储键名

  ExpenseProvider() {
    _loadData();
  }

  /// 获取排序后的记录（置顶项优先）
  List<Expense> get sortedExpenses {
    final pinned = _expenses.where((e) => e.isPinned).toList();
    final unpinned = _expenses.where((e) => !e.isPinned).toList();
    pinned.sort((a, b) => b.date.compareTo(a.date)); // 按日期倒序
    unpinned.sort((a, b) => b.date.compareTo(a.date));
    return [...pinned, ...unpinned];
  }

  double get totalAmount =>
      _expenses.fold(0, (sum, e) => sum + e.amount); // 总金额
  double get unclaimedAmount => // 未报账金额
      _expenses.where((e) => !e.isClaimed).fold(0, (sum, e) => sum + e.amount);

  Future<void> _loadData() async {
    // 从本地存储加载数据
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey);
    if (data != null) {
      _expenses =
          data
              .map((e) {
                final json = jsonDecode(e);
                return Expense.fromJson(json);
              })
              .toList()
              .cast<Expense>();
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    // 保存数据到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _expenses.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void addExpense(Expense expense) {
    // 添加新记录
    _expenses.insert(0, expense);
    _saveData();
    notifyListeners();
  }

  void toggleStatus(String id) {
    // 切换报账状态
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index].isClaimed = !_expenses[index].isClaimed;
      _saveData();
      notifyListeners();
    }
  }

  void togglePin(String id) {
    // 切换置顶状态
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index].isPinned = !_expenses[index].isPinned;
      _saveData();
      notifyListeners();
    }
  }

  void removeExpense(String id) {
    // 删除记录
    _expenses.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }
}

/// 主界面 - MVVM架构中的View
class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  ExpenseTrackerScreenState createState() => ExpenseTrackerScreenState();
}

class ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  // 添加加载状态
  bool _isLoading = true;

  // 关键动画控制器
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // 表单相关控制器
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  // 表单状态
  DateTime _selectedDate = DateTime.now();
  bool _isClaimed = false;

  // 定义动画时长常量
  static const int deleteAnimationDuration = 150; // 毫秒

  /// 日期选择方法
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  /// 表单提交方法
  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: double.parse(_amountController.text),
      purpose: _purposeController.text,
      date: _selectedDate,
      isClaimed: _isClaimed,
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.addExpense(newExpense);

    // 触发添加动画
    if (_listKey.currentState != null) {
      _listKey.currentState!.insertItem(
        0,
        duration: const Duration(milliseconds: deleteAnimationDuration),
      );
    }

    _resetForm();
  }

  /// 表单重置方法
  void _resetForm() {
    _amountController.clear();
    _purposeController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _isClaimed = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // 加载数据
    _loadData();
  }

  /// 数据加载方法
  Future<void> _loadData() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider._loadData();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0, // 防止滚动时出现阴影
        title: Text(
          '报账了吗',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildInputCard(), // 输入表单卡片
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                      : _buildAnimatedList(),
            ), // 动画列表
            _buildSummaryBar(), // 底部统计栏
          ],
        ),
      ),
    );
  }

  /// 使用AnimatedList实现带动画的列表
  Widget _buildAnimatedList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return AnimatedList(
          key: _listKey, // 控制动画的关键键
          initialItemCount: provider.sortedExpenses.length,
          itemBuilder: (context, index, animation) {
            // 确保索引有效
            if (index >= provider.sortedExpenses.length) {
              return const SizedBox.shrink();
            }
            return _buildAnimatedItem(
              provider.sortedExpenses[index],
              index,
              context,
              animation,
            );
          },
        );
      },
    );
  }

  /// 构建带动画的列表项
  Widget _buildAnimatedItem(
    Expense expense,
    int index,
    BuildContext context,
    Animation<double> animation,
  ) {
    return SizeTransition(
      // 大小变化动画
      sizeFactor: animation,
      child: FadeTransition(
        // 淡入淡出动画
        opacity: animation,
        child: Slidable(
          // 可滑动操作组件
          key: Key(expense.id),
          closeOnScroll: true,
          endActionPane: ActionPane(
            // 右滑操作区域
            motion: const ScrollMotion(),
            extentRatio: 0.4, // 占宽比例
            children: [
              // 自定义置顶按钮
              _buildPinAction(expense, context),
              const SizedBox(width: 5), // 按钮间距
              // 自定义删除按钮
              _buildDeleteAction(expense, context, index),
            ],
          ),
          child: AnimatedSwitcher(
            // 状态变化动画
            duration: const Duration(milliseconds: 300),
            child: _ExpenseItem(expense: expense),
          ),
        ),
      ),
    );
  }

  /// 构建与主界面风格一致的置顶操作按钮
  Widget _buildPinAction(Expense expense, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Provider.of<ExpenseProvider>(
            context,
            listen: false,
          ).togglePin(expense.id);
        },
        child: Card(
          margin: const EdgeInsets.all(5), // 外边距
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ), // 圆角
          elevation: 2, // 阴影深度
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expense.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                expense.isPinned ? '取消置顶' : '置顶',
                style: const TextStyle(fontSize: 14, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建与主界面风格一致的删除操作按钮 - 修复删除功能和异步操作警告
  Widget _buildDeleteAction(Expense expense, BuildContext context, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // 提前获取 Provider 实例
          final provider = Provider.of<ExpenseProvider>(context, listen: false);

          // 先删除数据，再播放动画 - 这是修复的关键
          provider.removeExpense(expense.id);

          // 播放删除动画
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildRemovingItem(expense, animation),
            duration: const Duration(milliseconds: deleteAnimationDuration),
          );
        },
        child: Card(
          margin: const EdgeInsets.all(5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete, color: Colors.red, size: 24),
              const SizedBox(height: 4),
              const Text(
                '删除',
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建删除动画中的项目
  Widget _buildRemovingItem(Expense expense, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: IgnorePointer(child: _ExpenseItem(expense: expense)),
      ),
    );
  }

  /// 构建输入表单卡片
  Widget _buildInputCard() {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2, // 轻微阴影
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 金额输入和状态选择行
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _commonInputDecoration(
                        context,
                      ).copyWith(hintText: '金额'),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return '请输入金额';
                        if (num.tryParse(value!) == null) return '请输入数字';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: InputDecorator(
                      decoration: _commonInputDecoration(context),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<bool>(
                          borderRadius: BorderRadius.circular(8),
                          isExpanded: true,
                          isDense: true,
                          value: _isClaimed,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[700],
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                          items: const [
                            DropdownMenuItem(value: false, child: Text('未报账')),
                            DropdownMenuItem(value: true, child: Text('已报账')),
                          ],
                          onChanged:
                              (value) => setState(() => _isClaimed = value!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 用途和日期选择行
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _purposeController,
                      decoration: _commonInputDecoration(
                        context,
                      ).copyWith(hintText: '用途'),
                      validator:
                          (value) => value?.isEmpty ?? true ? '请输入用途' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: _commonInputDecoration(context),
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 添加记录按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                onPressed: _submitForm,
                child: const Text(
                  '添加记录',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 通用输入框样式
  InputDecoration _commonInputDecoration(BuildContext context) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _inputBorder(),
      enabledBorder: _inputBorder(),
      focusedBorder: _inputBorder(color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
    );
  }

  /// 输入框边框样式
  InputBorder _inputBorder({Color? color}) => OutlineInputBorder(
    borderSide: BorderSide(color: color ?? Colors.grey[300]!, width: 1.5),
    borderRadius: BorderRadius.circular(8),
  );

  /// 构建底部统计栏
  Widget _buildSummaryBar() {
    return Consumer<ExpenseProvider>(
      builder:
          (context, provider, child) => Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('总金额', provider.totalAmount),
                _buildSummaryItem(
                  '未报账',
                  provider.unclaimedAmount,
                  isDanger: true,
                ),
              ],
            ),
          ),
    );
  }

  /// 构建统计项组件
  Widget _buildSummaryItem(
    String label,
    double value, {
    bool isDanger = false,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          '¥${value.toStringAsFixed(2)}', // 金额格式化显示
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
}

/// 单个消费记录项组件
class _ExpenseItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ), // 圆角
      elevation: 2, // 阴影深度
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            // 置顶状态指示器
            if (expense.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.push_pin, color: Colors.orange, size: 18),
              ),
            // 记录详情
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(expense.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.purpose,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // 金额显示
            Text(
              '¥${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color:
                    expense.isClaimed
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.secondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            // 报账状态切换按钮
            GestureDetector(
              onTap:
                  () => Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).toggleStatus(expense.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      expense.isClaimed
                          ? Colors.green[100] // 已报账状态背景色
                          : Colors.orange[100], // 未报账状态背景极
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  expense.isClaimed ? '已报账' : '未报账',
                  style: TextStyle(
                    color:
                        expense.isClaimed
                            ? Colors.green[800] // 已报账状态文字色
                            : Colors.orange[800], // 未报账状态文字色
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
