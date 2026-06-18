// 消费记录数据模型

class Expense {
  final String id;
  final double amount;
  final String purpose;
  final DateTime date;
  bool isBilled;
  bool isPinned;
  final String fromPerson;
  final String? categoryId;
  bool isDeleted;

  Expense({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.date,
    this.isBilled = false,
    this.isPinned = false,
    this.fromPerson = '-',
    this.categoryId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'purpose': purpose,
    'date': date.toIso8601String(),
    'isBilled': isBilled,
    'isPinned': isPinned,
    'fromPerson': fromPerson,
    'categoryId': categoryId,
    'isDeleted': isDeleted,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    amount: json['amount'],
    purpose: json['purpose'],
    date: DateTime.parse(json['date']),
    isBilled: json['isBilled'],
    isPinned: json['isPinned'] ?? false,
    fromPerson: json['fromPerson'],
    categoryId: json['categoryId'],
    isDeleted: json['isDeleted'] ?? false,
  );

  Expense copyWith({
    String? id,
    double? amount,
    String? purpose,
    DateTime? date,
    bool? isBilled,
    bool? isPinned,
    String? fromPerson,
    String? categoryId,
    bool? isDeleted,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      date: date ?? this.date,
      isBilled: isBilled ?? this.isBilled,
      isPinned: isPinned ?? this.isPinned,
      fromPerson: fromPerson ?? this.fromPerson,
      categoryId: categoryId ?? this.categoryId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
