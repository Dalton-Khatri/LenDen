import 'package:cloud_firestore/cloud_firestore.dart';

/// Smart amount formatter: shows up to 3 decimal places, trims trailing zeros.
/// 67.667 → "67.667", 100.0 → "100", 50.500 → "50.5"
extension AmountFormat on double {
  String get fmt {
    if (this == truncateToDouble()) return toStringAsFixed(0);
    final s = toStringAsFixed(3);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

enum TransactionType { iGave, iTook }

class Friend {
  final String id;
  final String name;
  final String emoji;
  final String? photoUrl;
  final String userId;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.name,
    required this.emoji,
    this.photoUrl,
    required this.userId,
    required this.createdAt,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '👤',
      photoUrl: data['photoUrl'],
      userId: data['userId'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'emoji': emoji,
        'photoUrl': photoUrl,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class MoneyTransaction {
  final String id;
  final String friendId;
  final String userId;
  final double amount;
  final TransactionType type;
  final String reason;
  final String? note;
  final DateTime date;
  final bool isSettled;
  final bool isStarred;

  MoneyTransaction({
    required this.id,
    required this.friendId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    this.note,
    required this.date,
    this.isSettled = false,
    this.isStarred = false,
  });

  factory MoneyTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoneyTransaction(
      id: doc.id,
      friendId: data['friendId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      type: data['type'] == 'iGave'
          ? TransactionType.iGave
          : TransactionType.iTook,
      reason: data['reason'] ?? '',
      note: data['note'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSettled: data['isSettled'] ?? false,
      isStarred: data['isStarred'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'friendId': friendId,
        'userId': userId,
        'amount': amount,
        'type': type == TransactionType.iGave ? 'iGave' : 'iTook',
        'reason': reason,
        'note': note,
        'date': Timestamp.fromDate(date),
        'isSettled': isSettled,
        'isStarred': isStarred,
      };
}