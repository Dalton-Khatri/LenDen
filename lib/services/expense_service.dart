import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _expensesCol(String uid) =>
      _db.collection('users').doc(uid).collection('expenses');

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('expense');

  // ─── CATEGORIES ──────────────────────────────────────────
  /// Stream of user-created categories (stored as a list in settings doc).
  Stream<List<String>> categoriesStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _settingsDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data() ?? {};
      final cats = List<String>.from(data['categories'] ?? []);
      return cats;
    });
  }

  Future<void> addCategory(String category) async {
    final uid = _uid!;
    await _settingsDoc(uid).set({
      'categories': FieldValue.arrayUnion([category.trim()]),
    }, SetOptions(merge: true));
  }

  Future<void> removeCategory(String category) async {
    final uid = _uid!;
    await _settingsDoc(uid).update({
      'categories': FieldValue.arrayRemove([category]),
    });
  }

  // ─── EXPENSES ────────────────────────────────────────────
  /// Stream all expenses for a given month/year.
  Stream<List<Expense>> expensesStream(int year, int month) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return _expensesCol(uid)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
      final list = s.docs.map(Expense.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addExpense(Expense expense) async {
    final uid = _uid!;
    await _expensesCol(uid).doc(expense.id).set(expense.toFirestore());
    // Auto-add category if new
    final snap = await _settingsDoc(uid).get();
    final cats = List<String>.from(
        (snap.data() ?? {})['categories'] ?? []);
    if (!cats.contains(expense.category)) {
      await addCategory(expense.category);
    }
  }

  Future<void> deleteExpense(String id) async {
    final uid = _uid!;
    await _expensesCol(uid).doc(id).delete();
  }

  // ─── MONTHLY TARGET ──────────────────────────────────────
  Stream<double?> monthlyTargetStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _settingsDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      final target = data['monthlyTarget'];
      return target != null ? (target as num).toDouble() : null;
    });
  }

  Future<void> setMonthlyTarget(double amount) async {
    final uid = _uid!;
    await _settingsDoc(uid).set({
      'monthlyTarget': amount,
    }, SetOptions(merge: true));
  }
}
