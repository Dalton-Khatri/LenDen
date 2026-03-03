import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';
import '../widgets/friend_avatar.dart';
import 'add_friend_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  final FirebaseService service;
  final Friend? preselectedFriend;

  const AddTransactionScreen({
    super.key,
    required this.service,
    this.preselectedFriend,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  Friend? _selectedFriend;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.iGave;
  DateTime _date = DateTime.now();
  bool _loading = false;
  List<Friend> _friends = [];

  @override
  void initState() {
    super.initState();
    _selectedFriend = widget.preselectedFriend;
    widget.service.friendsStream().listen((friends) {
      if (mounted) setState(() => _friends = friends);
    });
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFriendSelector().animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildTypeSelector().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildAmountField().animate(delay: 150.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildReasonField().animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildNoteField().animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildDatePicker().animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 28),
                      _buildSubmitButton().animate(delay: 350.ms).fadeIn().scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ),
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
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 18),
          ),
          const SizedBox(width: 16),
          Text('New Transaction',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildFriendSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Select Friend'),
          const SizedBox(height: 10),
          if (_friends.isEmpty)
            Center(
              child: Text('No friends yet. Add one first!',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 13)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._friends.map((f) {
                  final selected = _selectedFriend?.id == f.id;
                  final photoUrl = f.photoUrl;
                  final hasPhoto = photoUrl != null &&
                      photoUrl.isNotEmpty &&
                      File(photoUrl).existsSync();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFriend = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accentPurple.withValues(alpha: 0.4)
                            : AppTheme.glassWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.glowPurple
                              : AppTheme.glassBorder,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(
                                color: AppTheme.glowPurple.withValues(alpha: 0.3),
                                blurRadius: 10)]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show photo or emoji
                          hasPhoto
                              ? CircleAvatar(
                                  radius: 12,
                                  backgroundImage:
                                      FileImage(File(photoUrl!)),
                                )
                              : Text(f.emoji,
                                  style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            f.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                // Add new friend chip
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) =>
                        AddFriendDialog(service: widget.service),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: AppTheme.softPurple, size: 16),
                        const SizedBox(width: 6),
                        Text('New Friend',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.softPurple)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Transaction Type'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _typeButton(
                  label: '💸 I Gave',
                  subtitle: 'They owe me',
                  type: TransactionType.iGave,
                  activeColor: AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _typeButton(
                  label: '🤝 I Took',
                  subtitle: 'I owe them',
                  type: TransactionType.iTook,
                  activeColor: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required String subtitle,
    required TransactionType type,
    required Color activeColor,
  }) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : AppTheme.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : AppTheme.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? activeColor : AppTheme.textPrimary)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: selected
                        ? activeColor.withValues(alpha: 0.7)
                        : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Amount (रु)'),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
              prefixText: 'रु ',
              prefixStyle: GoogleFonts.poppins(
                  color: AppTheme.softPurple,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Reason *'),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Lunch at Bhojan Griha, Bus fare...',
              hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.description_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Note (optional)'),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Any extra details...',
              hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.note_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return GlassCard(
      onTap: _pickDate,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppTheme.softPurple, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textSecondary)),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_date),
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit_calendar_rounded,
              color: AppTheme.textSecondary, size: 16),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final typeColor = _type == TransactionType.iGave
        ? AppTheme.successGreen
        : AppTheme.dangerRed;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _type == TransactionType.iGave
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text('Save Transaction',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_selectedFriend == null) {
      _showError('Please select a friend');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      _showError('Please enter a reason');
      return;
    }

    setState(() => _loading = true);
    try {
      final txn = MoneyTransaction(
        id: const Uuid().v4(),
        friendId: _selectedFriend!.id,
        userId: widget.service.currentUserId!,
        amount: amount,
        type: _type,
        reason: _reasonController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _date,
      );
      await widget.service.addTransaction(txn);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      _showError('Error saving: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: AppTheme.dangerRed,
    ));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}