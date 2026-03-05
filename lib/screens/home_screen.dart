import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';
import '../widgets/friend_avatar.dart';
import 'add_transaction_screen.dart';
import 'friend_detail_screen.dart';
import 'analysis_screen.dart';
import 'add_friend_dialog.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService service;
  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, double> _balances = {};
  final Map<String, StreamSubscription> _balanceSubs = {};
  List<Friend> _friends = [];
  bool _loadingFriends = true;
  late StreamSubscription _friendsSub;

  @override
  void initState() {
    super.initState();
    _friendsSub = widget.service.friendsStream().listen((friends) {
      if (!mounted) return;
      // Subscribe to balance stream for new friends only
      for (final f in friends) {
        if (!_balanceSubs.containsKey(f.id)) {
          _subscribeToBalance(f.id);
        }
      }
      // Cancel subs for removed friends
      final currentIds = friends.map((f) => f.id).toSet();
      final removed =
          _balanceSubs.keys.where((id) => !currentIds.contains(id)).toList();
      for (final id in removed) {
        _balanceSubs[id]?.cancel();
        _balanceSubs.remove(id);
        _balances.remove(id);
      }
      setState(() {
        _friends = friends;
        _loadingFriends = false;
      });
    });
  }

  void _subscribeToBalance(String friendId) {
    final sub =
        widget.service.transactionsStream(friendId).listen((transactions) {
      if (!mounted) return;
      double net = 0;
      for (final t in transactions) {
        if (!t.isSettled) {
          net += t.type == TransactionType.iGave ? t.amount : -t.amount;
        }
      }
      if (_balances[friendId] != net) {
        setState(() => _balances[friendId] = net);
      }
    });
    _balanceSubs[friendId] = sub;
  }

  @override
  void dispose() {
    _friendsSub.cancel();
    for (final sub in _balanceSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  // ── Long press → Settle All ──
  void _onLongPress(Friend friend) {
    final balance = _balances[friend.id] ?? 0;
    if (balance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${friend.name} is already fully settled!',
            style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.textSecondary,
      ));
      return;
    }
    _showSettleAllDialog(friend);
  }

  void _showSettleAllDialog(Friend friend) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FriendAvatar(friend: friend, size: 64),
              const SizedBox(height: 14),
              Text(
                'Settle All with\n${friend.name}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'All active transactions will be marked as settled.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.service.settleAllForFriend(friend.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'All settled with ${friend.name}! 🎉',
                                style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.successGreen,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Settle All',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete Friend ──
  void _confirmDeleteFriend(Friend friend) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded,
                  color: AppTheme.dangerRed, size: 44),
              const SizedBox(height: 12),
              Text(
                'Delete ${friend.name}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently delete ${friend.name} and ALL their transactions. This cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await widget.service.deleteFriend(friend.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('${friend.name} deleted.',
                                style: GoogleFonts.poppins()),
                            backgroundColor: AppTheme.dangerRed,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Delete',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepPurple,
      body: PurpleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loadingFriends
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.glowPurple))
                    : _friends.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _friends.length,
                            itemBuilder: (context, i) {
                              return _buildFriendTile(_friends[i], i)
                                  .animate(
                                    delay: Duration(milliseconds: i * 60),
                                    onComplete: (c) => c.stop(),
                                  )
                                  .fadeIn(duration: 350.ms)
                                  .slideX(begin: 0.15, end: 0);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(service: widget.service),
          ),
        ),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text('Add',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LenDen',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.softPurple, AppTheme.lightPurple],
                    ).createShader(const Rect.fromLTWH(0, 0, 160, 40)),
                ),
              ),
              Text('Paisa Saathi 💜',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          Row(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AnalysisScreen(service: widget.service),
                  ),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: AppTheme.softPurple, size: 22),
              ),
              const SizedBox(width: 10),
              GlassCard(
                padding: const EdgeInsets.all(10),
                onTap: _showAddFriendDialog,
                child: const Icon(Icons.person_add_rounded,
                    color: AppTheme.softPurple, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(Friend friend, int index) {
    final balance = _balances[friend.id] ?? 0;
    final isOwed = balance > 0;
    final isNeutral = balance == 0;
    final balanceColor = isNeutral
        ? AppTheme.textSecondary
        : (isOwed ? AppTheme.successGreen : AppTheme.dangerRed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendDetailScreen(
                friend: friend,
                service: widget.service,
              ),
            ),
          ),
          onLongPress: () => _onLongPress(friend),
          child: GlassCard(
            child: Row(
              children: [
                FriendAvatar(friend: friend, size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        isNeutral
                            ? 'All settled ✓'
                            : (isOwed ? 'owes you' : 'you owe'),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: balanceColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  isNeutral
                      ? 'रु 0'
                      : '${isOwed ? "+" : "-"}रु ${balance.abs().fmt}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(width: 4),
                // ── 3-dot menu ──
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  color: AppTheme.purple1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'settle') _showSettleAllDialog(friend);
                    if (v == 'delete') _confirmDeleteFriend(friend);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'settle',
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.successGreen, size: 18),
                        const SizedBox(width: 10),
                        Text('Settle All',
                            style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.dangerRed, size: 18),
                        const SizedBox(width: 10),
                        Text('Delete Friend',
                            style: GoogleFonts.poppins(
                                color: AppTheme.dangerRed)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💸', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No friends yet!',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Add a friend to get started',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddFriendDialog,
            icon: const Icon(Icons.person_add_rounded),
            label: Text('Add Friend',
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddFriendDialog(service: widget.service),
    );
  }
}