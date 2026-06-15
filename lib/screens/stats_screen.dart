import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/filter_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _monthlyData = [];
  int _touchedIndex = -1;
  bool _showExpense = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    final provider = context.read<ExpenseProvider>();
    final data = await provider.getMonthlyChartData();
    if (mounted) setState(() => _monthlyData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'الفئات'),
            Tab(text: 'الشهري'),
          ],
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryTab(provider: provider, touchedIndex: _touchedIndex,
                  onTouch: (i) => setState(() => _touchedIndex = i),
                  showExpense: _showExpense,
                  onToggle: () => setState(() { _showExpense = !_showExpense; _touchedIndex = -1; })),
              _MonthlyTab(monthlyData: _monthlyData),
            ],
          );
        },
      ),
    );
  }
}

// ─── CATEGORY PIE TAB ────────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  final ExpenseProvider provider;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final bool showExpense;
  final VoidCallback onToggle;

  const _CategoryTab({
    required this.provider,
    required this.touchedIndex,
    required this.onTouch,
    required this.showExpense,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final data = showExpense ? provider.expenseByCategory : provider.incomeByCategory;
    final total = showExpense ? provider.totalExpense : provider.totalIncome;
    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const FilterBar(),
        const SizedBox(height: 16),

        // Toggle
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _ToggleBtn(label: '💸 المصاريف', active: showExpense, onTap: () { if (!showExpense) onToggle(); }),
              _ToggleBtn(label: '💰 الدخل', active: !showExpense, onTap: () { if (showExpense) onToggle(); }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (entries.isEmpty)
          _EmptyChart(showExpense: showExpense)
        else ...[
          // Pie chart
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      final idx = e.key;
                      final cat = provider.getCategoryById(e.value.key);
                      final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
                      final isTouched = idx == touchedIndex;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: cat?.color ?? AppColors.categoryColors[idx % AppColors.categoryColors.length],
                        radius: isTouched ? 80 : 65,
                        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        badgeWidget: isTouched ? null : null,
                      );
                    }).toList(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (response?.touchedSection != null) {
                          onTouch(response!.touchedSection!.touchedSectionIndex);
                        } else {
                          onTouch(-1);
                        }
                      },
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touchedIndex >= 0 && touchedIndex < entries.length
                          ? provider.getCategoryById(entries[touchedIndex].key)?.emoji ?? '💳'
                          : (showExpense ? '💸' : '💰'),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      touchedIndex >= 0 && touchedIndex < entries.length
                          ? Formatters.currency(entries[touchedIndex].value)
                          : Formatters.currency(total),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    Text(
                      touchedIndex >= 0 && touchedIndex < entries.length
                          ? provider.getCategoryById(entries[touchedIndex].key)?.name ?? ''
                          : 'الإجمالي',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Legend list
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final cat = provider.getCategoryById(e.value.key);
            final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
            final color = cat?.color ?? AppColors.categoryColors[idx % AppColors.categoryColors.length];

            return GestureDetector(
              onTap: () => onTouch(idx == touchedIndex ? -1 : idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: touchedIndex == idx ? color.withOpacity(0.1) : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: touchedIndex == idx ? color : AppColors.divider,
                    width: touchedIndex == idx ? 1.5 : 1,
                  ),
                  boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(cat?.emoji ?? '💳', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat?.name ?? 'أخرى',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: color.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Formatters.currency(e.value.value),
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── MONTHLY BAR TAB ─────────────────────────────────────────────────────────

class _MonthlyTab extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const _MonthlyTab({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    // Build per-month income & expense
    final Map<String, Map<String, double>> byMonth = {};
    for (final row in monthlyData) {
      final month = row['month'] as String;
      final type = row['type'] as String;
      final total = (row['total'] as num).toDouble();
      byMonth.putIfAbsent(month, () => {'income': 0, 'expense': 0});
      byMonth[month]![type] = total;
    }

    final months = byMonth.keys.toList()..sort();
    final arabicMonths = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
        'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

    if (months.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('لا توجد بيانات لهذا العام',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final maxVal = byMonth.values
        .expand((m) => m.values)
        .fold(0.0, (m, v) => v > m ? v : m);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإيرادات والمصاريف الشهرية ${DateTime.now().year}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Legend(color: AppColors.income, label: 'دخل'),
                  const SizedBox(width: 16),
                  _Legend(color: AppColors.expense, label: 'مصروف'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxVal * 1.2,
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final m = months[group.x];
                          final type = rodIndex == 0 ? 'دخل' : 'مصروف';
                          return BarTooltipItem(
                            '$type\n${Formatters.currency(rod.toY)}',
                            const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (v, _) => Text(
                            Formatters.compact(v),
                            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            if (v.toInt() >= months.length) return const SizedBox();
                            final monthStr = months[v.toInt()];
                            final mIdx = int.tryParse(monthStr.split('-').last) ?? 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                arabicMonths[mIdx - 1].substring(0, 3),
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: months.asMap().entries.map((e) {
                      final data = byMonth[e.value]!;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: data['income'] ?? 0,
                            color: AppColors.income,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                          BarChartRodData(
                            toY: data['expense'] ?? 0,
                            color: AppColors.expense,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Monthly summary list
        ...months.reversed.map((m) {
          final data = byMonth[m]!;
          final inc = data['income'] ?? 0;
          final exp = data['expense'] ?? 0;
          final bal = inc - exp;
          final mIdx = int.tryParse(m.split('-').last) ?? 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primaryLighter, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text(arabicMonths[mIdx - 1].substring(0, 3),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(arabicMonths[mIdx - 1],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                      Row(
                        children: [
                          Text('↑ ${Formatters.compact(inc)}', style: const TextStyle(fontSize: 12, color: AppColors.income)),
                          const SizedBox(width: 8),
                          Text('↓ ${Formatters.compact(exp)}', style: const TextStyle(fontSize: 12, color: AppColors.expense)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.currency(bal),
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: bal >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ],
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,2))] : [],
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 14,
          ),
        ),
      ),
    ),
  );
}

class _EmptyChart extends StatelessWidget {
  final bool showExpense;
  const _EmptyChart({required this.showExpense});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Text(showExpense ? '📊' : '💰', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('لا توجد ${showExpense ? "مصاريف" : "دخل"} في هذه الفترة',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15), textAlign: TextAlign.center),
      ],
    ),
  );
}
