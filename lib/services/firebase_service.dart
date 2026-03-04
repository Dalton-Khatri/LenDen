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
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();
  Future<void> signOut() => _auth.signOut();
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> _friendsCol(String uid) =>
      _db.collection('users').doc(uid).collection('friends');

  CollectionReference<Map<String, dynamic>> _txnsCol(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  // ─── FRIENDS ─────────────────────────────────────────────
  Stream<List<Friend>> friendsStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _friendsCol(uid)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Friend.fromFirestore).toList());
  }

  /// Check duplicate name. Pass excludeId to skip the friend being edited.
  Future<String?> checkDuplicateName(String name,
      {String? excludeId}) async {
    final uid = currentUserId!;
    final snap = await _friendsCol(uid)
        .where('name', isEqualTo: name.trim())
        .limit(2)
        .get();
    for (final doc in snap.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      return 'A friend named "$name" already exists.';
    }
    return null;
  }

  /// Add friend. Returns null on success, error string on failure.
  Future<String?> addFriend(
    String name,
    String emoji, {
    String? photoPath,
  }) async {
    final uid = currentUserId!;
    final trimmed = name.trim();
    final dupError = await checkDuplicateName(trimmed);
    if (dupError != null) return dupError;

    final id = _uuid.v4();
    final friend = Friend(
      id: id,
      name: trimmed,
      emoji: emoji,
      photoUrl: photoPath,
      userId: uid,
      createdAt: DateTime.now(),
    );
    await _friendsCol(uid).doc(id).set(friend.toFirestore());
    return null;
  }

  /// Update friend name, emoji, photo. Returns updated Friend.
  Future<Friend> updateFriend(
    String friendId, {
    required String name,
    required String emoji,
    String? photoPath,
  }) async {
    final uid = currentUserId!;
    final updates = <String, dynamic>{
      'name': name.trim(),
      'emoji': emoji,
      'photoUrl': photoPath,
    };
    await _friendsCol(uid).doc(friendId).update(updates);
    // Return updated Friend object
    final doc = await _friendsCol(uid).doc(friendId).get();
    return Friend.fromFirestore(doc);
  }

  Future<void> deleteFriend(String friendId) async {
    final uid = currentUserId!;
    final txns = await _txnsCol(uid)
        .where('friendId', isEqualTo: friendId)
        .get();
    final batch = _db.batch();
    for (final doc in txns.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_friendsCol(uid).doc(friendId));
    await batch.commit();
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────
  Stream<List<MoneyTransaction>> transactionsStream(String friendId) {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _txnsCol(uid)
        .where('friendId', isEqualTo: friendId)
        .snapshots()
        .map((s) {
      final list = s.docs.map(MoneyTransaction.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<MoneyTransaction>> allTransactionsStream() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _txnsCol(uid).snapshots().map((s) {
      final list = s.docs.map(MoneyTransaction.fromFirestore).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addTransaction(MoneyTransaction txn) async {
    final uid = currentUserId!;
    await _txnsCol(uid).doc(txn.id).set(txn.toFirestore());
  }

  Future<void> settleTransaction(String txnId) async {
    final uid = currentUserId!;
    await _txnsCol(uid).doc(txnId).update({'isSettled': true});
  }

  Future<void> settleAllForFriend(String friendId) async {
    final uid = currentUserId!;
    final snap = await _txnsCol(uid)
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

  Future<void> toggleStarTransaction(String txnId, bool current) async {
    final uid = currentUserId!;
    await _txnsCol(uid).doc(txnId).update({'isStarred': !current});
  }

  Future<void> deleteTransaction(String txnId) async {
    final uid = currentUserId!;
    await _txnsCol(uid).doc(txnId).delete();
  }
}