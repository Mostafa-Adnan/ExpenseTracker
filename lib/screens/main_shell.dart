import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';  // ← أضف هذا الـ import

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    StatsScreen(),
    CategoriesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().init();
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
    ? Directionality(
        textDirection: TextDirection.rtl, // لحل مشكلة RTL تماماً
        child: FloatingActionButton.extended(
          heroTag: 'add_transaction_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'إضافة', // تم اختصار النص ليكون أخف
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          // هذه الخصائص هي المفتاح لحل المشكلة
          extendedPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          extendedIconLabelSpacing: 6,
          elevation: 4,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          // منع الزر من أخذ مسافة كبيرة
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      )
    : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLighter,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'الإحصائيات',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category_rounded, color: AppColors.primary),
              label: 'الفئات',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}