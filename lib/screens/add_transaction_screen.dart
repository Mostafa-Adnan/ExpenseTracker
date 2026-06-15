import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late TabController _tabController;
  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _type = _tabController.index == 0
              ? TransactionType.expense
              : TransactionType.income;
          _selectedCategoryId = null;
        });
      }
    });

    if (_isEditing) {
      final tx = widget.transaction!;
      _titleCtrl.text = tx.title;
      _amountCtrl.text = tx.amount.toString();
      _noteCtrl.text = tx.note ?? '';
      _type = tx.type;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _tabController.index = _type == TransactionType.expense ? 0 : 1;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار فئة'), backgroundColor: AppColors.expense),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<ExpenseProvider>();
      final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));

      if (_isEditing) {
        await provider.updateTransaction(
          widget.transaction!.copyWith(
            title: _titleCtrl.text.trim(),
            amount: amount,
            type: _type,
            categoryId: _selectedCategoryId,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            date: _selectedDate,
          ),
        );
      } else {
        await provider.addTransaction(
          title: _titleCtrl.text.trim(),
          amount: amount,
          type: _type,
          categoryId: _selectedCategoryId!,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          date: _selectedDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'تم تعديل العملية' : 'تم إضافة العملية'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.expense),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == TransactionType.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل العملية' : 'عملية جديدة'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.expense,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('حذف العملية', textAlign: TextAlign.right),
                    content: const Text('هل تريد حذف هذه العملية؟', textAlign: TextAlign.right),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await context.read<ExpenseProvider>().deleteTransaction(widget.transaction!.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isExpense ? AppColors.expense : AppColors.income).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: '💸 مصروف'),
                    Tab(text: '💰 دخل'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isExpense
                        ? [AppColors.expense.withOpacity(0.08), AppColors.expenseLight]
                        : [AppColors.income.withOpacity(0.08), AppColors.incomeLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isExpense ? AppColors.expense : AppColors.income).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'المبلغ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: isExpense ? AppColors.expense : AppColors.income,
                            fontWeight: FontWeight.w800,
                          ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        hintText: '0',
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل المبلغ';
                        final n = double.tryParse(v.replaceAll(',', ''));
                        if (n == null || n <= 0) return 'مبلغ غير صحيح';
                        return null;
                      },
                    ),
                    Text(
                      'دينار عراقي',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleCtrl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'مثال: غداء مع العائلة',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل وصفاً' : null,
              ),
              const SizedBox(height: 12),

              // Category picker
              _CategoryPicker(
                selectedId: _selectedCategoryId,
                type: _type,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: 12),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteCtrl,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  hintText: 'أضف تفاصيل إضافية...',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpense ? AppColors.expense : AppColors.income,
                  shadowColor: (isExpense ? AppColors.expense : AppColors.income).withOpacity(0.4),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'حفظ التعديلات' : 'إضافة العملية',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String? selectedId;
  final TransactionType type;
  final ValueChanged<String> onSelected;

  const _CategoryPicker({
    required this.selectedId,
    required this.type,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 8),
              child: Text('الفئة', style: Theme.of(context).textTheme.titleMedium),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = cat.id == selectedId;
                return GestureDetector(
                  onTap: () => onSelected(cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? cat.color : cat.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? cat.color : cat.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: cat.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
