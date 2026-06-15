import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/pdf_exporter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              _SummaryCard(provider: provider),
              const SizedBox(height: 20),

              // Export section
              _SectionTitle(title: '📤 تصدير البيانات'),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.expense,
                title: 'تصدير PDF',
                subtitle: 'تصدير جميع العمليات كملف PDF',
                onTap: () => _exportPdf(context, provider),
              ),

              const SizedBox(height: 20),

              // About section
              _SectionTitle(title: 'ℹ️ عن التطبيق'),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                title: 'الإصدار',
                subtitle: '1.0.0',
                onTap: null,
              ),
              _SettingTile(
                icon: Icons.code_rounded,
                iconColor: AppColors.secondary,
                title: 'المطور',
                subtitle: 'مصطفى عدنان محمد',
                onTap: null,
              ),

              const SizedBox(height: 20),

              // Danger zone
              _SectionTitle(title: '⚠️ منطقة الخطر'),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.expense,
                title: 'حذف جميع البيانات',
                subtitle: 'لا يمكن التراجع عن هذا الإجراء',
                onTap: () => _confirmDeleteAll(context, provider),
                textColor: AppColors.expense,
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, ExpenseProvider provider) async {
    final transactions = provider.filteredTransactions;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد عمليات للتصدير'), backgroundColor: AppColors.expense),
      );
      return;
    }

    final period = _getPeriodLabel(provider.filterPeriod);
    try {
      await PdfExporter.exportTransactions(
        transactions: transactions,
        categories: provider.categories,
        totalIncome: provider.totalIncome,
        totalExpense: provider.totalExpense,
        balance: provider.balance,
        periodLabel: period,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e'), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  String _getPeriodLabel(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.week: return 'هذا الأسبوع';
      case FilterPeriod.month:
        return DateFormat('MMMM yyyy', 'ar').format(DateTime.now());
      case FilterPeriod.year: return 'سنة ${DateTime.now().year}';
      case FilterPeriod.all: return 'جميع العمليات';
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, ExpenseProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف جميع البيانات', textAlign: TextAlign.right,
            style: TextStyle(color: AppColors.expense)),
        content: const Text(
          'سيتم حذف جميع عملياتك المالية نهائياً. هل أنت متأكد؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Delete all transactions one by one
      final ids = List<String>.from(provider.allTransactions.map((t) => t.id));
      for (final id in ids) {
        await provider.deleteTransaction(id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف جميع البيانات'), backgroundColor: AppColors.income),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final ExpenseProvider provider;
  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalTx = provider.allTransactions.length;
    final balance = provider.allTimeBalance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CBF), Color(0xFF9B7FD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          const Text('ملخص الحساب', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(Formatters.currency(balance),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('الرصيد الإجمالي', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(label: 'عمليات', value: '$totalTx', icon: '📋'),
              _StatChip(label: 'دخل', value: Formatters.compact(
                  provider.allTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount)), icon: '↑'),
              _StatChip(label: 'مصاريف', value: Formatters.compact(
                  provider.allTransactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount)), icon: '↓'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value, icon;
  const _StatChip({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(icon, style: const TextStyle(color: Colors.white, fontSize: 18)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    this.onTap, this.textColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor ?? AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
      trailing: onTap != null ? const Icon(Icons.chevron_left_rounded, color: AppColors.textHint) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
  );
}
