import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'هذا الأسبوع',
                period: FilterPeriod.week,
                selected: provider.filterPeriod == FilterPeriod.week,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'هذا الشهر',
                period: FilterPeriod.month,
                selected: provider.filterPeriod == FilterPeriod.month,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'هذه السنة',
                period: FilterPeriod.year,
                selected: provider.filterPeriod == FilterPeriod.year,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'الكل',
                period: FilterPeriod.all,
                selected: provider.filterPeriod == FilterPeriod.all,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final FilterPeriod period;
  final bool selected;

  const _FilterChip({
    required this.label,
    required this.period,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ExpenseProvider>().setFilterPeriod(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
