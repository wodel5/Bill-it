import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final int colorValue;
  final String iconName;
  final bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconName = 'category',
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  IconData get icon => _iconMap[iconName] ?? Icons.category;

  static const _iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'work': Icons.work,
    'hotel': Icons.hotel,
    'category': Icons.category,
    'shopping_bag': Icons.shopping_bag,
    'local_hospital': Icons.local_hospital,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
    'pets': Icons.pets,
    'flight': Icons.flight,
    'fitness_center': Icons.fitness_center,
    'celebration': Icons.celebration,
    'coffee': Icons.coffee,
    'home': Icons.home,
  };

  static const _iconNames = [
    'category',
    'restaurant',
    'directions_car',
    'work',
    'hotel',
    'shopping_bag',
    'local_hospital',
    'school',
    'sports_esports',
    'pets',
    'flight',
    'fitness_center',
    'celebration',
    'coffee',
    'home',
  ];

  static const _defaultColors = [
    0xFF9E9E9E,
    0xFFFF9800,
    0xFF2196F3,
    0xFF607D8B,
    0xFF9C27B0,
    0xFFE91E63,
    0xFFF44336,
    0xFF795548,
    0xFF4CAF50,
    0xFF8D6E63,
    0xFF00BCD4,
    0xFFFF5722,
    0xFFFFC107,
    0xFF6D4C41,
    0xFF3F51B5,
  ];

  static List<ExpenseCategory> get defaults => [
    ExpenseCategory(id: 'default_food', name: '餐饮', colorValue: 0xFFFF9800, iconName: 'restaurant', isDefault: true),
    ExpenseCategory(id: 'default_transport', name: '交通', colorValue: 0xFF2196F3, iconName: 'directions_car', isDefault: true),
    ExpenseCategory(id: 'default_office', name: '办公', colorValue: 0xFF607D8B, iconName: 'work', isDefault: true),
    ExpenseCategory(id: 'default_lodging', name: '住宿', colorValue: 0xFF9C27B0, iconName: 'hotel', isDefault: true),
    ExpenseCategory(id: 'default_other', name: '其他', colorValue: 0xFF9E9E9E, iconName: 'category', isDefault: true),
  ];

  static List<String> get availableIconNames => List.unmodifiable(_iconNames);

  static List<int> get availableColors => List.unmodifiable(_defaultColors);

  static IconData iconForName(String name) => _iconMap[name] ?? Icons.category;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'iconName': iconName,
    'isDefault': isDefault,
  };

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
    id: json['id'],
    name: json['name'],
    colorValue: json['colorValue'],
    iconName: json['iconName'] ?? 'category',
    isDefault: json['isDefault'] ?? false,
  );
}
