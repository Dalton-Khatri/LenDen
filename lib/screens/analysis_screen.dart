import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';
import '../widgets/friend_avatar.dart';

class AnalysisScreen extends StatefulWidget {
  final FirebaseService service;
  const AnalysisScreen({super.key, required this.service});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final Map<String, double> _balances = {};
  final Map<String, StreamSubscription> _balanceSubs = {};
  List<Friend> _friends = [];
  List<MoneyTransaction> _allTransactions = [];
  bool _loading = true;
  bool _exporting = false;
  late StreamSubscription _friendsSub;
  late StreamSubscription _txnSub;

  int _selectedTab = 0; // 0 = Summary, 1 = Starred

  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _friendsSub = widget.service.friendsStream().listen((friends) {
      if (!mounted) return;
      for (final f in friends) {
        if (!_balanceSubs.containsKey(f.id)) _subscribeToBalance(f.id);
      }
      final ids = friends.map((f) => f.id).toSet();
      final removed =
          _balanceSubs.keys.where((id) => !ids.contains(id)).toList();
      for (final id in removed) {
        _balanceSubs[id]?.cancel();
        _balanceSubs.remove(id);
        _balances.remove(id);
      }
      setState(() {
        _friends = friends;
        _loading = false;
      });
    });

    _txnSub = widget.service.allTransactionsStream().listen((txns) {
      if (!mounted) return;
      setState(() => _allTransactions = txns);
    });
  }

  void _subscribeToBalance(String friendId) {
    final sub =
        widget.service.transactionsStream(friendId).listen((txns) {
      if (!mounted) return;
      double net = 0;
      for (final t in txns) {
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
    _txnSub.cancel();
    for (final sub in _balanceSubs.values) sub.cancel();
    super.dispose();
  }

  List<MoneyTransaction> get _starredTransactions {
    final list = _allTransactions.where((t) => t.isStarred).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Friend? _friendById(String id) {
    try {
      return _friends.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalReceive = 0, totalPay = 0;
    for (final b in _balances.values) {
      if (b > 0) totalReceive += b;
      if (b < 0) totalPay += b.abs();
    }
    final net = totalReceive - totalPay;

    return Scaffold(
      backgroundColor: AppTheme.deepPurple,
      body: PurpleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildToggle(),
              const SizedBox(height: 4),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.glowPurple))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: _selectedTab == 0
                            ? _buildSummaryTab(
                                totalReceive, totalPay, net,
                                key: const ValueKey('summary'))
                            : _buildStarredTab(
                                key: const ValueKey('starred')),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Clean pill toggle ──────────────────────────────────────
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Row(
          children: [
            _toggleBtn(index: 0, icon: Icons.bar_chart_rounded, label: 'Summary'),
            _toggleBtn(index: 1, icon: Icons.star_rounded, label: 'Starred'),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(
      {required int index,
      required IconData icon,
      required String label}) {
    final active = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTab != index) setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accentPurple.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active
                    ? AppTheme.softPurple
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.normal,
                  color: active
                      ? AppTheme.softPurple
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 18),
          ),
          const SizedBox(width: 16),
          Text('Analysis',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          Text(DateFormat('MMM yyyy').format(DateTime.now()),
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── SUMMARY TAB ──────────────────────────────────────────
  Widget _buildSummaryTab(
      double totalReceive, double totalPay, double net,
      {Key? key}) {
    if (_friends.isEmpty) {
      return _buildEmptyState('No friends yet', key: key);
    }
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        _buildTotalsCards(totalReceive, totalPay, net),
        const SizedBox(height: 20),
        Text('Per Friend',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ..._friends.map((f) => _buildFriendRow(f)),
        const SizedBox(height: 20),
        _buildDateRangeSelector(),
        const SizedBox(height: 12),
        _buildFullPDFButton(),
      ],
    );
  }

  Widget _buildTotalsCards(
      double totalReceive, double totalPay, double net) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                border: Border.all(
                    color: AppTheme.successGreen.withValues(alpha: 0.3)),
                child: Column(children: [
                  Text('To Receive',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('रु ${totalReceive.fmt}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successGreen)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                border: Border.all(
                    color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                child: Column(children: [
                  Text('To Pay',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('रु ${totalPay.fmt}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.dangerRed)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          border: Border.all(
              color: net >= 0
                  ? AppTheme.glowPurple.withValues(alpha: 0.3)
                  : AppTheme.dangerRed.withValues(alpha: 0.3)),
          child: Column(children: [
            Text('Net Position',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              net == 0
                  ? '🎉 All Clear!'
                  : '${net > 0 ? "+" : ""}रु ${net.fmt}',
              style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: net == 0
                      ? AppTheme.softPurple
                      : (net > 0
                          ? AppTheme.successGreen
                          : AppTheme.dangerRed)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildFriendRow(Friend friend) {
    final balance = _balances[friend.id] ?? 0;
    final isOwed = balance > 0;
    final isNeutral = balance == 0;
    final color = isNeutral
        ? AppTheme.textSecondary
        : (isOwed ? AppTheme.successGreen : AppTheme.dangerRed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        border: Border.all(
            color: isNeutral
                ? AppTheme.glassBorder
                : color.withValues(alpha: 0.25)),
        child: Row(
          children: [
            FriendAvatar(friend: friend, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Text(friend.name,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isNeutral
                      ? 'Settled ✓'
                      : '${isOwed ? "+" : "-"}रु ${balance.abs().fmt}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                if (!isNeutral)
                  Text(isOwed ? 'owes you' : 'you owe',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PDF Date Range',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateTile(
                  label: 'From',
                  date: _fromDate,
                  onTap: () async {
                    final d =
                        await _pickDate(_fromDate, last: _toDate);
                    if (d != null) setState(() => _fromDate = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateTile(
                  label: 'To',
                  date: _toDate,
                  onTap: () async {
                    final d =
                        await _pickDate(_toDate, first: _fromDate);
                    if (d != null) setState(() => _toDate = d);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text(DateFormat('dd MMM yyyy').format(date),
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial,
      {DateTime? first, DateTime? last}) {
    final lastDate = last ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(2020),
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentPurple,
            surface: AppTheme.purple1,
          ),
        ),
        child: child!,
      ),
    );
  }

  Widget _buildFullPDFButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _exportFullPDF,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.3),
          foregroundColor: AppTheme.softPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        icon: _exporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.softPurple))
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(
          _exporting ? 'Generating...' : 'Export Full PDF Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── STARRED TAB ──────────────────────────────────────────
  Widget _buildStarredTab({Key? key}) {
    final starred = _starredTransactions;
    if (starred.isEmpty) {
      return _buildEmptyState(
        'No starred transactions yet\nStar transactions from\nfriend detail screens ⭐',
        key: key,
      );
    }
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: starred.length,
      itemBuilder: (context, i) {
        final txn = starred[i];
        final friend = _friendById(txn.friendId);
        return _buildStarredCard(txn, friend);
      },
    );
  }

  Widget _buildStarredCard(MoneyTransaction txn, Friend? friend) {
    final isGave = txn.type == TransactionType.iGave;
    final color = txn.isSettled
        ? AppTheme.textSecondary
        : (isGave ? AppTheme.successGreen : AppTheme.dangerRed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        border: Border.all(
            color: AppTheme.goldAccent.withValues(alpha: 0.4),
            width: 1.5),
        child: Row(
          children: [
            const Icon(Icons.star_rounded,
                color: AppTheme.goldAccent, size: 20),
            const SizedBox(width: 8),
            if (friend != null) ...[
              FriendAvatar(friend: friend, size: 34),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.reason,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Row(children: [
                    if (friend != null)
                      Text('${friend.name} • ',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    Text(DateFormat('dd MMM yyyy').format(txn.date),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                  ]),
                  if (txn.isSettled)
                    Text('Settled',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isGave ? "+" : "-"}रु${txn.amount.fmt}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                Text(isGave ? 'I gave' : 'I took',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: color)),
              ],
            ),
            IconButton(
              onPressed: () =>
                  widget.service.toggleStarTransaction(txn.id, true),
              icon: const Icon(Icons.star_rounded,
                  color: AppTheme.goldAccent, size: 20),
              tooltip: 'Unstar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg, {Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 12),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 15, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── FULL PDF ──────────────────────────────────────────────
  Future<void> _exportFullPDF() async {
    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day, 0, 0, 0);
    final to = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59, 999);

    final filtered = _allTransactions
        .where((t) =>
            (t.date.isAfter(from) || t.date.isAtSameMomentAs(from)) &&
            (t.date.isBefore(to) || t.date.isAtSameMomentAs(to)))
        .toList();

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No transactions in selected date range.',
            style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.dangerRed,
      ));
      return;
    }

    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      final Map<String, List<MoneyTransaction>> byFriend = {};
      for (final t in filtered) {
        byFriend.putIfAbsent(t.friendId, () => []).add(t);
      }
      for (final list in byFriend.values) {
        list.sort((a, b) => b.date.compareTo(a.date));
      }

      double grandGave = 0, grandTook = 0;
      for (final t in filtered) {
        if (t.type == TransactionType.iGave) {
          grandGave += t.amount;
        } else {
          grandTook += t.amount;
        }
      }
      final grandNet = grandGave - grandTook;

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LenDen',
                        style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepPurple)),
                    pw.Text('Full Transaction Report',
                        style: const pw.TextStyle(
                            fontSize: 13, color: PdfColors.grey)),
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        '${DateFormat('dd MMM yyyy').format(_fromDate)}  →  ${DateFormat('dd MMM yyyy').format(_toDate)}',
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey)),
                  ]),
            ],
          ));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Divider(color: PdfColors.deepPurple200));
          widgets.add(pw.SizedBox(height: 16));

          for (final friendId in byFriend.keys) {
            final friend = _friendById(friendId);
            final friendName = friend?.name ?? 'Unknown';
            final txns = byFriend[friendId]!;

            double gave = 0, took = 0;
            for (final t in txns) {
              if (t.type == TransactionType.iGave) {
                gave += t.amount;
              } else {
                took += t.amount;
              }
            }
            final friendNet = gave - took;

            widgets.add(pw.Container(
              color: PdfColors.deepPurple100,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(friendName,
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepPurple900)),
                  pw.Text(
                    friendNet == 0
                        ? 'Settled'
                        : '${friendNet > 0 ? "+" : "-"}Rs ${friendNet.abs().fmt}',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: friendNet == 0
                            ? PdfColors.grey
                            : (friendNet > 0
                                ? PdfColors.green800
                                : PdfColors.red800)),
                  ),
                ],
              ),
            ));

            widgets.add(pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              child: pw.Row(children: [
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10))),
                pw.Expanded(
                    flex: 4,
                    child: pw.Text('Reason',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Type',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Amount',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Status',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10))),
              ]),
            ));

            for (int i = 0; i < txns.length; i++) {
              final t = txns[i];
              final isGave = t.type == TransactionType.iGave;
              widgets.add(pw.Container(
                color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          DateFormat('dd MMM yy').format(t.date),
                          style: const pw.TextStyle(fontSize: 9))),
                  pw.Expanded(
                      flex: 4,
                      child: pw.Text(t.reason,
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(isGave ? 'I Gave' : 'I Took',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: isGave
                                  ? PdfColors.green800
                                  : PdfColors.red800))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          'Rs ${t.amount.fmt}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: isGave
                                  ? PdfColors.green800
                                  : PdfColors.red800))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          t.isSettled ? '✓ Cleared' : 'Pending',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: t.isSettled
                                  ? PdfColors.green700
                                  : PdfColors.orange700))),
                ]),
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          widgets.add(pw.Divider(color: PdfColors.deepPurple300));
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
                color: PdfColors.deepPurple50,
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(children: [
              pw.Text('Overall Summary',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.deepPurple)),
              pw.SizedBox(height: 10),
              _pdfRow('Total I Gave',
                  'Rs ${grandGave.fmt}',
                  PdfColors.green800),
              pw.SizedBox(height: 6),
              _pdfRow('Total I Took',
                  'Rs ${grandTook.fmt}',
                  PdfColors.red800),
              pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Divider(color: PdfColors.grey400)),
              _pdfRow(
                grandNet >= 0
                    ? 'Net Gain (others owe you)'
                    : 'Net Loss (you owe others)',
                'Rs ${grandNet.abs().fmt}',
                grandNet >= 0
                    ? PdfColors.deepPurple
                    : PdfColors.red,
                isBold: true,
                fontSize: 13,
              ),
            ]),
          ));
          widgets.add(pw.SizedBox(height: 16));
          widgets.add(pw.Center(
              child: pw.Text(
                  'Generated by LenDen • Paisa Saathi',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey))));
          return widgets;
        },
      ));

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/lenden_report_${DateFormat('ddMMyyyy').format(_fromDate)}_${DateFormat('ddMMyyyy').format(_toDate)}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'LenDen Full Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export error: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfRow(String label, String value, PdfColor color,
      {bool isBold = false, double fontSize = 11}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: isBold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    );
  }
}