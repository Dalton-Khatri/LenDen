import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

import '../services/firebase_service.dart';
import '../services/expense_service.dart';
import '../utils/theme.dart';
import '../widgets/background.dart';
import '../widgets/glass_card.dart';
import 'day_expense_screen.dart';


class ExpenseTrackerScreen extends StatefulWidget {
  final FirebaseService service;
  const ExpenseTrackerScreen({super.key, required this.service});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  List<Expense> _prevMonthExpenses = [];
  double? _monthlyTarget;
  bool _loading = true;

  late int _year;
  late int _month;
  StreamSubscription? _expSub;
  StreamSubscription? _prevSub;
  StreamSubscription? _targetSub;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _subscribeToData();
  }

  void _subscribeToData() {
    _expSub?.cancel();
    _prevSub?.cancel();
    _targetSub?.cancel();

    _expSub = _expenseService.expensesStream(_year, _month).listen((exps) {
      if (mounted) setState(() { _expenses = exps; _loading = false; });
    });

    final prevMonth = _month == 1 ? 12 : _month - 1;
    final prevYear = _month == 1 ? _year - 1 : _year;
    _prevSub = _expenseService.expensesStream(prevYear, prevMonth).listen((exps) {
      if (mounted) setState(() => _prevMonthExpenses = exps);
    });

    _targetSub = _expenseService.monthlyTargetStream().listen((t) {
      if (mounted) setState(() => _monthlyTarget = t);
    });
  }

  @override
  void dispose() {
    _expSub?.cancel();
    _prevSub?.cancel();
    _targetSub?.cancel();
    super.dispose();
  }

  double get _totalThisMonth =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get _totalPrevMonth =>
      _prevMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Group expenses by day (descending).
  Map<DateTime, List<Expense>> get _groupedByDay {
    final map = <DateTime, List<Expense>>{};
    for (final e in _expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    // Sort keys descending (newest first)
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
    return sorted;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month > 12) { _month = 1; _year++; }
      if (_month < 1) { _month = 12; _year--; }
      _loading = true;
    });
    _subscribeToData();
  }

  void _openDay(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayExpenseScreen(
          service: _expenseService,
          userId: widget.service.currentUserId!,
          date: date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth =
        _year == DateTime.now().year && _month == DateTime.now().month;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: PurpleBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildMonthSelector(isCurrentMonth),
              const SizedBox(height: 4),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : _buildBody(),
              ),
            ],
          ),
        ),
      ),
      // FAB creates a new day section for today
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDay(DateTime.now()),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text('New Day',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ──
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
          const SizedBox(width: 14),
          Text('Expenses',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const Spacer(),
          // How it works icon
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: _showHowItWorks,
            child: const Icon(Icons.info_outline_rounded,
                color: AppTheme.softAccent, size: 20),
          ),
          const SizedBox(width: 8),
          // Target icon
          GlassCard(
            padding: const EdgeInsets.all(8),
            onTap: _showSetTargetDialog,
            child: const Icon(Icons.flag_rounded,
                color: AppTheme.goldAccent, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Month Selector ──
  Widget _buildMonthSelector(bool isCurrentMonth) {
    final label = DateFormat('MMMM yyyy').format(DateTime(_year, _month));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppTheme.textSecondary),
            onPressed: () => _changeMonth(-1),
          ),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: isCurrentMonth
                    ? AppTheme.cardBorder
                    : AppTheme.textSecondary),
            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  // ── Body: Summary + Day Sections ──
  Widget _buildBody() {
    final days = _groupedByDay;
    final monthDiff = _totalThisMonth - _totalPrevMonth;
    final diffPercent = _totalPrevMonth > 0
        ? (monthDiff / _totalPrevMonth * 100)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Monthly summary row
        Row(
          children: [
            Expanded(
              child: GlassCard(
                child: Column(children: [
                  Text('This Month',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('रु ${_totalThisMonth.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                child: Column(children: [
                  Text('vs Last Month',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        monthDiff <= 0
                            ? Icons.trending_down_rounded
                            : Icons.trending_up_rounded,
                        size: 18,
                        color: monthDiff <= 0
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                      ),
                      const SizedBox(width: 4),
                      Text('${diffPercent.abs().toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: monthDiff <= 0
                                  ? AppTheme.successGreen
                                  : AppTheme.dangerRed)),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Budget progress
        if (_monthlyTarget != null && _monthlyTarget! > 0) ...[
          _buildBudgetCard(),
          const SizedBox(height: 14),
        ],

        // Day sections header
        if (days.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('DAILY BREAKDOWN',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.5)),
          ),

        // Day cards
        ...days.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value.key;
          final dayExpenses = entry.value.value;
          return _buildDayCard(day, dayExpenses, i);
        }),

        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  Text('No expenses this month',
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text('Tap "New Day" to start tracking',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCard(DateTime day, List<Expense> expenses, int index) {
    final dayTotal = expenses.fold(0.0, (s, e) => s + e.amount);
    final isToday = day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;
    final categories = expenses.map((e) => e.category).toSet();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => _openDay(day),
        border: isToday
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
            : null,
        child: Row(
          children: [
            // Date circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isToday
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('dd').format(day),
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  Text(DateFormat('E').format(day),
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday
                        ? 'Today'
                        : DateFormat('dd MMMM').format(day),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expenses.length} expense${expenses.length == 1 ? "" : "s"} • ${categories.join(", ")}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Total
            Text('रु ${dayTotal.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildBudgetCard() {
    final target = _monthlyTarget!;
    final spent = _totalThisMonth;
    final progress = (spent / target).clamp(0.0, 1.0);
    final remaining = target - spent;
    final isOver = remaining < 0;

    return GlassCard(
      border: Border.all(
        color: isOver
            ? AppTheme.dangerRed.withValues(alpha: 0.4)
            : AppTheme.primary.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded,
                  color: AppTheme.goldAccent, size: 18),
              const SizedBox(width: 8),
              Text('Monthly Budget',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const Spacer(),
              Text('रु ${target.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppTheme.dangerRed : AppTheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOver
                ? 'Over budget by रु ${remaining.abs().toStringAsFixed(0)}'
                : 'रु ${remaining.toStringAsFixed(0)} remaining',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOver ? AppTheme.dangerRed : AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ── How It Works ──
  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('How Expense Tracker Works',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              _howStep('1', 'Create a Day',
                  'Tap the "New Day" button to open today\'s expense section. You can also tap any existing day to reopen it.'),
              _howStep('2', 'Add Expenses',
                  'Inside each day, tap + to add expenses. Pick a category (or create one), enter the amount and an optional note.'),
              _howStep('3', 'Track Monthly',
                  'The main screen shows all your days with totals. Browse months with the arrows to compare your spending.'),
              _howStep('4', 'Set a Target',
                  'Tap the 🚩 flag icon to set a monthly budget. A progress bar will show how much you\'ve used.'),
              _howStep('5', 'Categories',
                  'Categories are created by you — no defaults. They\'re saved and reused across all your expenses.'),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(desc,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Set Target Dialog ──
  void _showSetTargetDialog() {
    final controller = TextEditingController(
      text: _monthlyTarget != null ? _monthlyTarget!.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flag_rounded,
                  color: AppTheme.goldAccent, size: 36),
              const SizedBox(height: 12),
              Text('Set Monthly Budget',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Set a spending target for each month',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
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
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                        final val =
                            double.tryParse(controller.text.trim());
                        if (val != null && val > 0) {
                          await _expenseService.setMonthlyTarget(val);
                        }
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Set Target',
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
}
