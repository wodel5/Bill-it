import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data_models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _storageKey = 'categories';
  final List<ExpenseCategory> _categories = [];

  CategoryProvider() {
    loadData();
  }

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);

  ExpenseCategory? getById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey);
    if (data != null && data.isNotEmpty) {
      _categories
        ..clear()
        ..addAll(data.map((e) => ExpenseCategory.fromJson(jsonDecode(e))));
    } else {
      _categories
        ..clear()
        ..addAll(ExpenseCategory.defaults);
      await _saveData();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _categories.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void addCategory(ExpenseCategory category) {
    _categories.add(category);
    _saveData();
    notifyListeners();
  }

  void removeCategory(String id) {
    final cat = getById(id);
    if (cat != null && cat.isDefault) return;
    _categories.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();
  }
}
