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
  bool _loading = true;
  bool _exporting = false;
  late StreamSubscription _friendsSub;

  @override
  void initState() {
    super.initState();
    _friendsSub = widget.service.friendsStream().listen((friends) {
      if (!mounted) return;
      for (final f in friends) {
        if (!_balanceSubs.containsKey(f.id)) _subscribeToBalance(f.id);
      }
      final ids = friends.map((f) => f.id).toSet();
      final removed = _balanceSubs.keys.where((id) => !ids.contains(id)).toList();
      for (final id in removed) {
        _balanceSubs[id]?.cancel();
        _balanceSubs.remove(id);
        _balances.remove(id);
      }
      setState(() { _friends = friends; _loading = false; });
    });
  }

  void _subscribeToBalance(String friendId) {
    final sub = widget.service.transactionsStream(friendId).listen((txns) {
      if (!mounted) return;
      double net = 0;
      for (final t in txns) {
        if (!t.isSettled) net += t.type == TransactionType.iGave ? t.amount : -t.amount;
      }
      setState(() => _balances[friendId] = net);
    });
    _balanceSubs[friendId] = sub;
  }

  @override
  void dispose() {
    _friendsSub.cancel();
    for (final sub in _balanceSubs.values) sub.cancel();
    super.dispose();
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
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.glowPurple))
                    : _friends.isEmpty
                        ? _buildEmptyState()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              _buildSummaryCards(totalReceive, totalPay, net),
                              const SizedBox(height: 20),
                              Text('Per Friend',
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                              const SizedBox(height: 10),
                              ..._friends.map((f) => _buildFriendRow(f)),
                              const SizedBox(height: 16),
                              _buildExportButton(),
                            ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 18),
          ),
          const SizedBox(width: 16),
          Text('Analysis', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const Spacer(),
          Text(DateFormat('MMM yyyy').format(DateTime.now()),
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double totalReceive, double totalPay, double net) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                child: Column(children: [
                  Text('To Receive', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('रु ${totalReceive.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.successGreen)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                child: Column(children: [
                  Text('To Pay', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('रु ${totalPay.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.dangerRed)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          border: Border.all(
            color: net >= 0 ? AppTheme.glowPurple.withValues(alpha: 0.3) : AppTheme.dangerRed.withValues(alpha: 0.3),
          ),
          child: Column(children: [
            Text('Net Position', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(
              net == 0 ? '🎉 All Clear!' : '${net > 0 ? "+" : ""}रु ${net.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w800,
                color: net == 0 ? AppTheme.softPurple : (net > 0 ? AppTheme.successGreen : AppTheme.dangerRed),
              ),
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
    final color = isNeutral ? AppTheme.textSecondary : (isOwed ? AppTheme.successGreen : AppTheme.dangerRed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        border: Border.all(color: isNeutral ? AppTheme.glassBorder : color.withValues(alpha: 0.25)),
        child: Row(
          children: [
            FriendAvatar(friend: friend, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Text(friend.name,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isNeutral ? 'Settled ✓' : '${isOwed ? "+" : "-"}रु ${balance.abs().toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color),
                ),
                if (!isNeutral)
                  Text(isOwed ? 'owes you' : 'you owe',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _exportPDF,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.glassWhite,
          foregroundColor: AppTheme.softPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        icon: _exporting
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.softPurple))
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(_exporting ? 'Generating...' : 'Export PDF',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('LenDen — Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
            pw.Divider(height: 30),
            ..._friends.map((f) {
              final bal = _balances[f.id] ?? 0;
              final isOwed = bal > 0;
              final color = bal == 0 ? PdfColors.grey : (isOwed ? PdfColors.green : PdfColors.red);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(f.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      bal == 0 ? 'Settled' : '${isOwed ? "+" : "-"}Rs ${bal.abs().toStringAsFixed(0)}',
                      style: pw.TextStyle(fontSize: 16, color: color, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ));
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lenden_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'LenDen Summary');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text('No data yet', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}