import 'package:cloud_firestore/cloud_firestore.dart';


/// A single daily expense entry.
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'category': category,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Monthly budget target.
class MonthlyTarget {
  final double amount;
  final int month; // 1-12
  final int year;

  MonthlyTarget({
    required this.amount,
    required this.month,
    required this.year,
  });

  factory MonthlyTarget.fromMap(Map<String, dynamic> data) {
    return MonthlyTarget(
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'month': month,
        'year': year,
      };
}

/// Helper: group expenses by category.
Map<String, double> groupByCategory(List<Expense> expenses) {
  final map = <String, double>{};
  for (final e in expenses) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
}

/// Helper: daily totals.
Map<DateTime, double> dailyTotals(List<Expense> expenses) {
  final map = <DateTime, double>{};
  for (final e in expenses) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    map[day] = (map[day] ?? 0) + e.amount;
  }
  return map;
}
