import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';

/// Screen showing all expenses for a single day, with inline add.
class DayExpenseScreen extends StatefulWidget {
  final ExpenseService service;
  final String userId;
  final DateTime date;
  const DayExpenseScreen({
    super.key,
    required this.service,
    required this.userId,
    required this.date,
  });

  @override
  State<DayExpenseScreen> createState() => _DayExpenseScreenState();
}

class _DayExpenseScreenState extends State<DayExpenseScreen> {
  List<Expense> _expenses = [];
  List<String> _categories = [];
  StreamSubscription? _expSub;
  StreamSubscription? _catSub;

  // Inline add form state
  bool _showAddForm = false;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _newCatCtrl = TextEditingController();
  String? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final y = widget.date.year;
    final m = widget.date.month;
    _expSub = widget.service.expensesStream(y, m).listen((all) {
      if (!mounted) return;
      final dayOnly = all.where((e) =>
          e.date.year == widget.date.year &&
          e.date.month == widget.date.month &&
          e.date.day == widget.date.day).toList();
      setState(() => _expenses = dayOnly);
    });
    _catSub = widget.service.categoriesStream().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  void dispose() {
    _expSub?.cancel();
    _catSub?.cancel();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  double get _dayTotal => _expenses.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: PurpleBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd MMMM').format(widget.date),
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          Text(DateFormat('EEEE').format(widget.date),
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    // Day total badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('रु ${_dayTotal.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Expense list
              Expanded(
                child: _expenses.isEmpty && !_showAddForm
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📝',
                                style: TextStyle(fontSize: 50)),
                            const SizedBox(height: 12),
                            Text('No expenses yet',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            Text('Tap + to add your first expense',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        children: [
                          ..._expenses.asMap().entries.map((entry) =>
                              _buildExpenseItem(entry.value, entry.key)),
                          if (_showAddForm) _buildInlineAddForm(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAddForm = true),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(expense.category,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.softAccent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expense.note.isNotEmpty)
                    Text(expense.note,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                  Text(DateFormat('hh:mm a').format(expense.createdAt),
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Text('रु ${expense.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.dangerRed, size: 18),
              onPressed: () =>
                  widget.service.deleteExpense(expense.id),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildInlineAddForm() {
    return GlassCard(
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Expense',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary)),
          const SizedBox(height: 12),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  fontSize: 22),
              prefixText: 'रु ',
              prefixStyle: GoogleFonts.poppins(
                  color: AppTheme.softAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const Divider(color: AppTheme.cardBorder),

          // Category chips
          const SizedBox(height: 8),
          Text('Category',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._categories.map((cat) {
                final sel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary.withValues(alpha: 0.2)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.cardBorder),
                    ),
                    child: Text(cat,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: sel
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary)),
                  ),
                );
              }),
              // Inline add new category
              _buildAddCatChip(),
            ],
          ),
          const SizedBox(height: 10),

          // Note
          TextField(
            controller: _noteCtrl,
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Note (optional)',
              hintStyle: GoogleFonts.poppins(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() {
                    _showAddForm = false;
                    _amountCtrl.clear();
                    _noteCtrl.clear();
                    _selectedCategory = null;
                  }),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Add',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAddCatChip() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('New Category',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _newCatCtrl,
                    autofocus: true,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Category name',
                      hintStyle: GoogleFonts.poppins(
                          color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.cardBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _newCatCtrl.clear();
                            Navigator.pop(context);
                          },
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = _newCatCtrl.text.trim();
                            if (name.isNotEmpty) {
                              await widget.service.addCategory(name);
                              setState(
                                  () => _selectedCategory = name);
                              _newCatCtrl.clear();
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: Text('Add',
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
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded,
                color: AppTheme.softAccent, size: 14),
            const SizedBox(width: 3),
            Text('New',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.softAccent)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enter a valid amount',
            style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.dangerRed,
      ));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select or create a category',
            style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.dangerRed,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final expense = Expense(
        id: const Uuid().v4(),
        userId: widget.userId,
        amount: amount,
        category: _selectedCategory!,
        note: _noteCtrl.text.trim(),
        date: widget.date,
      );
      await widget.service.addExpense(expense);
      setState(() {
        _showAddForm = false;
        _amountCtrl.clear();
        _noteCtrl.clear();
        _selectedCategory = null;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.dangerRed,
        ));
      }
    }
  }
}
