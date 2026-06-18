//消费状态管理

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  //定义一个私有缓存，钥匙名为'expenseRecords'
  final _storageKey = 'expenseRecords';
  final List<Expense> _expenses = []; //空列表，类型为Expense，后续可以追加

  ExpenseProvider() {
    loadData();
  }

  List<Expense> get sortedExpenses {
    final active = _expenses.where((e) => !e.isDeleted).toList();
    final pinned = active.where((e) => e.isPinned).toList();
    final unpinned = active.where((e) => !e.isPinned).toList();
    pinned.sort((a, b) => b.date.compareTo(a.date));
    unpinned.sort((a, b) => b.date.compareTo(a.date));
    return [...pinned, ...unpinned];
  }

  List<Expense> get trashExpenses {
    return _expenses.where((e) => e.isDeleted).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalAmount =>
      _expenses.where((e) => !e.isDeleted).fold(0, (sum, e) => sum + e.amount);

  double get unclaimedAmount =>
      _expenses
          .where((e) => !e.isDeleted && !e.isBilled)
          .fold(0, (sum, e) => sum + e.amount);

  //载入数据：异步
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey);
    if (data != null) {
      _expenses
        ..clear()
        ..addAll(data.map((e) => Expense.fromJson(jsonDecode(e))));//解析JSON 字符串，逐条还原成 Expense 对象，加到内存列表里
      notifyListeners();//通知所有监听当前  ChangeNotifier  的 Widget，数据已经更新
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _expenses.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    _saveData();
    notifyListeners();
  }

  //切换报账状态
  void toggleStatus(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i != -1) {
      _expenses[i].isBilled = !_expenses[i].isBilled;
      _saveData();
      notifyListeners();
    }
  }

  //切换置顶状态
  void togglePin(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i != -1) {
      _expenses[i].isPinned = !_expenses[i].isPinned;
      _saveData();
      notifyListeners();
    }
  }

  //删除记录
  void moveToTrash(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i != -1) {
      _expenses[i].isDeleted = true;
      _saveData();
      notifyListeners();
    }
  }

  void restoreExpense(String id) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i != -1) {
      _expenses[i].isDeleted = false;
      _saveData();
      notifyListeners();
    }
  }

  void permanentlyDelete(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  void updateExpense(String id, Expense updated) {
    final i = _expenses.indexWhere((e) => e.id == id);
    if (i != -1) {
      _expenses[i] = updated;
      _saveData();
      notifyListeners();
    }
  }
}
