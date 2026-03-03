import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  String? get currentUserId => _auth.currentUser?.uid;

  // ─── AUTH ────────────────────────────────────────────────
  Future<UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── FRIENDS ─────────────────────────────────────────────
  Stream<List<Friend>> friendsStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Friend.fromFirestore).toList());
  }

  Future<Friend> addFriend(
    String name,
    String emoji, {
    String? photoPath,
  }) async {
    final uid = currentUserId!;
    final id = _uuid.v4();
    final friend = Friend(
      id: id,
      name: name,
      emoji: emoji,
      photoUrl: photoPath,
      userId: uid,
      createdAt: DateTime.now(),
    );
    await _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(id)
        .set(friend.toFirestore());
    return friend;
  }

  Future<void> deleteFriend(String friendId) async {
    final uid = currentUserId!;
    final txns = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('friendId', isEqualTo: friendId)
        .get();
    final batch = _db.batch();
    for (final doc in txns.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(friendId));
    await batch.commit();
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────
  Stream<List<MoneyTransaction>> transactionsStream(String friendId) {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('friendId', isEqualTo: friendId)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map(MoneyTransaction.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<MoneyTransaction>> allTransactionsStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .snapshots()
        .map((s) {
      final list =
          s.docs.map(MoneyTransaction.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addTransaction(MoneyTransaction txn) async {
    final uid = currentUserId!;
    await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(txn.id)
        .set(txn.toFirestore());
  }

  Future<void> settleTransaction(String txnId) async {
    final uid = currentUserId!;
    await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(txnId)
        .update({'isSettled': true});
  }

  Future<void> settleAllForFriend(String friendId) async {
    final uid = currentUserId!;
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('friendId', isEqualTo: friendId)
        .where('isSettled', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isSettled': true});
    }
    await batch.commit();
  }

  Future<void> deleteTransaction(String txnId) async {
    final uid = currentUserId!;
    await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(txnId)
        .delete();
  }
}