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

class AddExpenseScreen extends StatefulWidget {
  final ExpenseService service;
  final String userId;
  const AddExpenseScreen({
    super.key,
    required this.service,
    required this.userId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newCatController = TextEditingController();
  String? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _loading = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    widget.service.categoriesStream().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
                      _buildAmountField()
                          .animate()
                          .fadeIn()
                          .slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildCategorySelector()
                          .animate(delay: 100.ms)
                          .fadeIn()
                          .slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildNoteField()
                          .animate(delay: 200.ms)
                          .fadeIn()
                          .slideY(begin: 0.1),
                      const SizedBox(height: 14),
                      _buildDatePicker()
                          .animate(delay: 300.ms)
                          .fadeIn()
                          .slideY(begin: 0.1),
                      const SizedBox(height: 28),
                      _buildSubmitButton()
                          .animate(delay: 350.ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.9, 0.9)),
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
          Text('Add Expense',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
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
                  color: AppTheme.softAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label('Category')),
              GestureDetector(
                onTap: _showManageCategoriesSheet,
                child: Text('Manage',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_categories.isEmpty)
            _addCategoryInline()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
                // + Add category chip
                GestureDetector(
                  onTap: _showAddCategoryDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: AppTheme.softAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('Add',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.softAccent)),
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

  Widget _addCategoryInline() {
    return Column(
      children: [
        Text('No categories yet. Add your first one!',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCatController,
                style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Food, Transport...',
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final name = _newCatController.text.trim();
                if (name.isNotEmpty) {
                  await widget.service.addCategory(name);
                  _newCatController.clear();
                  setState(() => _selectedCategory = name);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
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
                controller: controller,
                autofocus: true,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Category name',
                  hintStyle: GoogleFonts.poppins(
                      color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        final name = controller.text.trim();
                        if (name.isNotEmpty) {
                          await widget.service.addCategory(name);
                          setState(() => _selectedCategory = name);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
  }

  void _showManageCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ManageCategoriesSheet(service: widget.service),
    );
  }

  Widget _buildNoteField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Note'),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            style: GoogleFonts.poppins(
                color: AppTheme.textPrimary, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'What was this expense for?',
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
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppTheme.softAccent, size: 20),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
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
                  const Icon(Icons.save_rounded),
                  const SizedBox(width: 8),
                  Text('Save Expense',
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
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showError('Please select or add a category');
      return;
    }

    setState(() => _loading = true);
    try {
      final expense = Expense(
        id: const Uuid().v4(),
        userId: widget.userId,
        amount: amount,
        category: _selectedCategory!,
        note: _noteController.text.trim(),
        date: _date,
      );
      await widget.service.addExpense(expense);
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
    _noteController.dispose();
    _newCatController.dispose();
    super.dispose();
  }
}

// ── Manage Categories Bottom Sheet ──────────────────────────
class _ManageCategoriesSheet extends StatefulWidget {
  final ExpenseService service;
  const _ManageCategoriesSheet({required this.service});

  @override
  State<_ManageCategoriesSheet> createState() =>
      _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  List<String> _categories = [];
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.service.categoriesStream().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Manage Categories',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 14),
            // Add category row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'New category name',
                      hintStyle: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final name = _addController.text.trim();
                    if (name.isNotEmpty) {
                      await widget.service.addCategory(name);
                      _addController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No categories yet',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppTheme.textSecondary)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(cat,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textPrimary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.dangerRed, size: 20),
                        onPressed: () async {
                          await widget.service.removeCategory(cat);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }
}
