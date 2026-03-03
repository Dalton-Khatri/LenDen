import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';
import '../widgets/friend_avatar.dart';
import 'add_transaction_screen.dart';

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;
  final FirebaseService service;

  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.service,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    widget.service.transactionsStream(widget.friend.id).listen((txns) {
      if (!mounted) return;
      setState(() {
        _transactions = txns;
        _loading = false;
      });
    });
  }

  double get _net {
    double net = 0;
    for (final t in _transactions.where((t) => !t.isSettled)) {
      net += t.type == TransactionType.iGave ? t.amount : -t.amount;
    }
    return net;
  }

  List<MoneyTransaction> get _sortedActive {
    final list = _transactions.where((t) => !t.isSettled).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<MoneyTransaction> get _sortedSettled {
    final list = _transactions.where((t) => t.isSettled).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepPurple,
      body: PurpleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildBalanceSummary(_net),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.glowPurple))
                    : _transactions.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            children: [
                              if (_sortedActive.isNotEmpty) ...[
                                _sectionHeader('Active'),
                                ..._sortedActive
                                    .map((t) => _buildTxnCard(context, t)),
                              ],
                              if (_sortedSettled.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _sectionHeader('Settled ✓'),
                                ..._sortedSettled.map((t) =>
                                    _buildTxnCard(context, t,
                                        isSettled: true)),
                              ],
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(
              service: widget.service,
              preselectedFriend: widget.friend,
            ),
          ),
        ),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // Header: back | avatar + name | spacer | PDF button
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 18),
          ),
          const SizedBox(width: 12),

          // Avatar
          FriendAvatar(friend: widget.friend, size: 42),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              widget.friend.name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // PDF export button — top right, same row
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: _exporting ? null : _exportPDF,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.softPurple),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded,
                        color: AppTheme.softPurple, size: 18),
                const SizedBox(width: 6),
                Text('PDF',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.softPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary(double net) {
    final isOwed = net > 0;
    final isNeutral = net == 0;
    final color = isNeutral
        ? AppTheme.textSecondary
        : (isOwed ? AppTheme.successGreen : AppTheme.dangerRed);
    final label = isNeutral
        ? 'All settled up! 🎉'
        : (isOwed
            ? '${widget.friend.name} owes you'
            : 'You owe ${widget.friend.name}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassCard(
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              isNeutral
                  ? 'No pending dues'
                  : 'रु ${net.abs().toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(title,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildTxnCard(BuildContext context, MoneyTransaction txn,
      {bool isSettled = false}) {
    final isGave = txn.type == TransactionType.iGave;
    final color = isSettled
        ? AppTheme.textSecondary
        : (isGave ? AppTheme.successGreen : AppTheme.dangerRed);
    final icon =
        isGave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        border: Border.all(
          color: isSettled
              ? AppTheme.glassBorder
              : color.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.reason,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSettled
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary)),
                  if (txn.note != null && txn.note!.isNotEmpty)
                    Text(txn.note!,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic)),
                  Text(DateFormat('dd MMM yyyy').format(txn.date),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isGave ? "+" : "-"}रु${txn.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSettled ? 'Settled' : (isGave ? 'I gave' : 'I took'),
                    style: GoogleFonts.poppins(fontSize: 10, color: color),
                  ),
                ),
              ],
            ),
            if (!isSettled)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textSecondary, size: 18),
                color: AppTheme.purple1,
                onSelected: (v) => _handleAction(context, v, txn),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'settle',
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppTheme.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Text('Mark Settled',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.dangerRed, size: 18),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary)),
                    ]),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _handleAction(
      BuildContext context, String action, MoneyTransaction txn) {
    if (action == 'settle') {
      widget.service.settleTransaction(txn.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Marked as settled!', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.successGreen,
      ));
    } else if (action == 'delete') {
      widget.service.deleteTransaction(txn.id);
    }
  }

  Future<void> _exportPDF() async {
    final active = _sortedActive;
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No active transactions to export!',
            style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.dangerRed,
      ));
      return;
    }

    setState(() => _exporting = true);
    try {
      double totalGave = 0, totalTook = 0;
      for (final t in active) {
        if (t.type == TransactionType.iGave) {
          totalGave += t.amount;
        } else {
          totalTook += t.amount;
        }
      }
      final net = totalGave - totalTook;

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LenDen',
                        style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.deepPurple)),
                    pw.Text('Transaction Report',
                        style: const pw.TextStyle(
                            fontSize: 13, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(widget.friend.name,
                        style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColors.deepPurple200),
            pw.SizedBox(height: 14),
            // Table header
            pw.Container(
              color: PdfColors.deepPurple50,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              child: pw.Row(children: [
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11))),
                pw.Expanded(
                    flex: 4,
                    child: pw.Text('Reason',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Type',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Amount',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11))),
              ]),
            ),
            // Rows
            ...active.asMap().entries.map((e) {
              final t = e.value;
              final isEven = e.key % 2 == 0;
              final isGave = t.type == TransactionType.iGave;
              return pw.Container(
                color: isEven ? PdfColors.white : PdfColors.grey100,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                child: pw.Row(children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          DateFormat('dd MMM yy').format(t.date),
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(t.reason,
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          if (t.note != null && t.note!.isNotEmpty)
                            pw.Text(t.note!,
                                style: const pw.TextStyle(
                                    fontSize: 9,
                                    color: PdfColors.grey600)),
                        ],
                      )),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(isGave ? 'I Gave' : 'I Took',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: isGave
                                  ? PdfColors.green800
                                  : PdfColors.red800))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          'Rs ${t.amount.toStringAsFixed(0)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: isGave
                                  ? PdfColors.green800
                                  : PdfColors.red800))),
                ]),
              );
            }),
            pw.SizedBox(height: 14),
            pw.Divider(color: PdfColors.deepPurple200),
            pw.SizedBox(height: 10),
            // Totals
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: const pw.BoxDecoration(
                color: PdfColors.deepPurple50,
                borderRadius:
                    pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(children: [
                _pdfRow('Total I Gave',
                    'Rs ${totalGave.toStringAsFixed(0)}',
                    PdfColors.green800),
                pw.SizedBox(height: 6),
                _pdfRow('Total I Took',
                    'Rs ${totalTook.toStringAsFixed(0)}',
                    PdfColors.red800),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Divider(color: PdfColors.grey400),
                ),
                _pdfRow(
                  net >= 0
                      ? '${widget.friend.name} owes you'
                      : 'You owe ${widget.friend.name}',
                  'Rs ${net.abs().toStringAsFixed(0)}',
                  net >= 0 ? PdfColors.deepPurple : PdfColors.red,
                  isBold: true,
                  fontSize: 13,
                ),
              ]),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text('Generated by LenDen • Paisa Saathi',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey)),
            ),
          ],
        ),
      ));

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final fileName =
          'lenden_${widget.friend.name.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'LenDen — ${widget.friend.name} transactions');
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text('No transactions yet',
              style: GoogleFonts.poppins(
                  fontSize: 16, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}