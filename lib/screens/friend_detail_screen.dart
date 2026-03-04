import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  const FriendDetailScreen(
      {super.key, required this.friend, required this.service});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  List<MoneyTransaction> _transactions = [];
  bool _loading = true;
  bool _exporting = false;

  // We keep a local mutable copy of friend so edits reflect immediately
  late Friend _friend;

  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
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

  // ── Edit Friend Dialog ──────────────────────────────────
  void _showEditFriend() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _EditFriendDialog(
        friend: _friend,
        service: widget.service,
        onUpdated: (updated) {
          if (mounted) setState(() => _friend = updated);
        },
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(
              service: widget.service,
              preselectedFriend: _friend,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          FriendAvatar(friend: _friend, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _friend.name,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // PDF button
          GlassCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            color: AppTheme.softPurple))
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
          const SizedBox(width: 8),
          // 3-dot menu for edit — no box, just the icon
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.textSecondary, size: 22),
            color: AppTheme.purple1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'edit') _showEditFriend();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit_rounded,
                      color: AppTheme.softPurple, size: 18),
                  const SizedBox(width: 10),
                  Text('Edit Friend',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary)),
                ]),
              ),
            ],
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
            ? '${_friend.name} owes you'
            : 'You owe ${_friend.name}');

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

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
        child: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5)),
      );

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
          color: txn.isStarred
              ? AppTheme.goldAccent.withValues(alpha: 0.5)
              : (isSettled
                  ? AppTheme.glassBorder
                  : color.withValues(alpha: 0.3)),
          width: txn.isStarred ? 1.5 : 1,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    if (txn.isStarred)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star_rounded,
                            color: AppTheme.goldAccent, size: 14),
                      ),
                    Expanded(
                      child: Text(txn.reason,
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSettled
                                  ? AppTheme.textSecondary
                                  : AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
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
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    isSettled ? 'Settled' : (isGave ? 'I gave' : 'I took'),
                    style:
                        GoogleFonts.poppins(fontSize: 10, color: color),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.textSecondary, size: 18),
              color: AppTheme.purple1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) => _handleTxnAction(context, v, txn),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'star',
                  child: Row(children: [
                    Icon(
                      txn.isStarred
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppTheme.goldAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(txn.isStarred ? 'Unstar' : 'Star',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary)),
                  ]),
                ),
                if (!isSettled)
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

  void _handleTxnAction(
      BuildContext context, String action, MoneyTransaction txn) {
    switch (action) {
      case 'star':
        widget.service.toggleStarTransaction(txn.id, txn.isStarred);
        break;
      case 'settle':
        widget.service.settleTransaction(txn.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Marked as settled!', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.successGreen,
        ));
        break;
      case 'delete':
        widget.service.deleteTransaction(txn.id);
        break;
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
      final pdf = pw.Document();
      double totalGave = 0, totalTook = 0;
      for (final t in active) {
        if (t.type == TransactionType.iGave) {
          totalGave += t.amount;
        } else {
          totalTook += t.amount;
        }
      }
      final net = totalGave - totalTook;

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
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(_friend.name,
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          DateFormat('dd MMM yyyy')
                              .format(DateTime.now()),
                          style: const pw.TextStyle(
                              fontSize: 11, color: PdfColors.grey)),
                    ]),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColors.deepPurple200),
            pw.SizedBox(height: 14),
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
            ...active.asMap().entries.map((e) {
              final t = e.value;
              final isGave = t.type == TransactionType.iGave;
              return pw.Container(
                color: e.key % 2 == 0
                    ? PdfColors.white
                    : PdfColors.grey100,
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
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
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
                          ])),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                          isGave ? 'I Gave' : 'I Took',
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
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: const pw.BoxDecoration(
                  color: PdfColors.deepPurple50,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(8))),
              child: pw.Column(children: [
                _pdfRow('Total I Gave',
                    'Rs ${totalGave.toStringAsFixed(0)}',
                    PdfColors.green800),
                pw.SizedBox(height: 6),
                _pdfRow('Total I Took',
                    'Rs ${totalTook.toStringAsFixed(0)}',
                    PdfColors.red800),
                pw.Padding(
                    padding:
                        const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Divider(color: PdfColors.grey400)),
                _pdfRow(
                  net >= 0
                      ? '${_friend.name} owes you'
                      : 'You owe ${_friend.name}',
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
                        fontSize: 9, color: PdfColors.grey))),
          ],
        ),
      ));

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/lenden_${_friend.name.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'LenDen — ${_friend.name} transactions');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export error: $e')));
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

  Widget _buildEmptyState() => Center(
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

// ── Edit Friend Dialog ────────────────────────────────────────
class _EditFriendDialog extends StatefulWidget {
  final Friend friend;
  final FirebaseService service;
  final ValueChanged<Friend> onUpdated;

  const _EditFriendDialog({
    required this.friend,
    required this.service,
    required this.onUpdated,
  });

  @override
  State<_EditFriendDialog> createState() => _EditFriendDialogState();
}

class _EditFriendDialogState extends State<_EditFriendDialog> {
  late TextEditingController _nameController;
  late String _selectedEmoji;
  String? _photoPath;
  bool _usePhoto = false;
  bool _loading = false;
  String? _nameError;

  final List<String> _emojis = [
    '👤', '😊', '🧑', '👩', '👦', '👧',
    '🧔', '👱', '🎓', '🏠', '💼', '🎮',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.friend.name);
    _selectedEmoji = widget.friend.emoji;
    _photoPath = widget.friend.photoUrl;
    _usePhoto =
        _photoPath != null && _photoPath!.isNotEmpty;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _photoPath = picked.path;
        _usePhoto = true;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.purple1,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Photo',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _photoBtn(Icons.camera_alt_rounded, 'Camera', () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  }),
                  _photoBtn(Icons.photo_library_rounded, 'Gallery',
                      () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  }),
                  if (_photoPath != null)
                    _photoBtn(Icons.delete_rounded, 'Remove', () {
                      Navigator.pop(context);
                      setState(() {
                        _photoPath = null;
                        _usePhoto = false;
                      });
                    }, color: AppTheme.dangerRed),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoBtn(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (color ?? AppTheme.accentPurple)
                  .withValues(alpha: 0.15),
              border: Border.all(
                  color: (color ?? AppTheme.glowPurple)
                      .withValues(alpha: 0.4)),
            ),
            child: Icon(icon,
                color: color ?? AppTheme.softPurple, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color ?? AppTheme.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _usePhoto &&
        _photoPath != null &&
        _photoPath!.isNotEmpty &&
        File(_photoPath!).existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Friend',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.softPurple)),
              const SizedBox(height: 20),

              // Avatar preview
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppTheme.accentPurple
                                .withValues(alpha: 0.5),
                            AppTheme.glowPurple.withValues(alpha: 0.3),
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.glowPurple
                                    .withValues(alpha: 0.3),
                                blurRadius: 16),
                          ],
                        ),
                        child: ClipOval(
                          child: hasPhoto
                              ? Image.file(File(_photoPath!),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80)
                              : Center(
                                  child: Text(_selectedEmoji,
                                      style: const TextStyle(
                                          fontSize: 36))),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentPurple,
                            border: Border.all(
                                color: AppTheme.deepPurple, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to change photo',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary)),
              ),
              const SizedBox(height: 16),

              // Emoji picker (only when no photo)
              if (!_usePhoto) ...[
                Text('Choose avatar',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojis.map((e) {
                    final sel = e == _selectedEmoji;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedEmoji = e),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel
                              ? AppTheme.accentPurple
                                  .withValues(alpha: 0.4)
                              : AppTheme.glassWhite,
                          border: Border.all(
                              color: sel
                                  ? AppTheme.glowPurple
                                  : AppTheme.glassBorder,
                              width: sel ? 2 : 1),
                        ),
                        child: Center(
                            child: Text(e,
                                style:
                                    const TextStyle(fontSize: 20))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Name
              TextField(
                controller: _nameController,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Friend's name",
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary),
                  errorText: _nameError,
                  filled: true,
                  fillColor: AppTheme.glassWhite,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.glassBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.glassBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.glowPurple, width: 2)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppTheme.dangerRed, width: 2)),
                ),
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
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('Save',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }
    setState(() => _loading = true);
    try {
      // Check duplicate only if name changed
      if (name.toLowerCase() !=
          widget.friend.name.toLowerCase()) {
        final err = await widget.service
            .checkDuplicateName(name, excludeId: widget.friend.id);
        if (err != null) {
          setState(() {
            _nameError = err;
            _loading = false;
          });
          return;
        }
      }
      final updated = await widget.service.updateFriend(
        widget.friend.id,
        name: name,
        emoji: _selectedEmoji,
        photoPath: _usePhoto ? _photoPath : null,
      );
      if (mounted) {
        widget.onUpdated(updated);
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _nameError = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}