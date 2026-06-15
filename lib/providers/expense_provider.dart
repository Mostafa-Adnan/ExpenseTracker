import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

enum FilterPeriod { week, month, year, all }

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  FilterPeriod _filterPeriod = FilterPeriod.month;
  String _searchQuery = '';
  bool _isLoading = false;

  List<TransactionModel> get filteredTransactions => _filteredTransactions;
  List<TransactionModel> get allTransactions => _transactions;
  List<CategoryModel> get categories => _categories;
  FilterPeriod get filterPeriod => _filterPeriod;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<TransactionModel> get _filteredTransactions {
    var list = _transactions;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.title.toLowerCase().contains(q) ||
        (t.note?.toLowerCase().contains(q) ?? false)).toList();
    }
    final range = dateRange;
    if (range != null) {
      list = list.where((t) =>
        !t.date.isBefore(range.$1) && !t.date.isAfter(range.$2)).toList();
    }
    return list;
  }

  (DateTime, DateTime)? get dateRange {
    final now = DateTime.now();
    switch (_filterPeriod) {
      case FilterPeriod.week:
        final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return (monday, DateTime(now.year, now.month, now.day, 23, 59, 59));
      case FilterPeriod.month:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case FilterPeriod.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
      case FilterPeriod.all:
        return null;
    }
  }

  double get totalIncome => _filteredTransactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
  double get totalExpense => _filteredTransactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
  double get balance => totalIncome - totalExpense;
  double get allTimeBalance {
    final inc = _transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final exp = _transactions.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    return inc - exp;
  }

  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final t in _filteredTransactions.where((t) => t.isExpense)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  Map<String, double> get incomeByCategory {
    final map = <String, double>{};
    for (final t in _filteredTransactions.where((t) => t.isIncome)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return ((totalIncome - totalExpense) / totalIncome * 100).clamp(0, 100);
  }

  CategoryModel? getCategoryById(String id) {
    try { return _categories.firstWhere((c) => c.id == id); } catch (_) { return null; }
  }

  Future<void> init() async {
  _isLoading = true;
  notifyListeners();
  try {
    await loadCategories();
    await loadTransactions();
  } catch (e) {
    debugPrint('Error initializing: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> loadTransactions() async {
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  Future<TransactionModel> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    String? note,
    required DateTime date,
  }) async {
    final tx = TransactionModel(
      id: _uuid.v4(), title: title, amount: amount, type: type,
      categoryId: categoryId, note: note, date: date, createdAt: DateTime.now(),
    );
    await _db.insertTransaction(tx);
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    return tx;
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.updateTransaction(tx);
    final i = _transactions.indexWhere((t) => t.id == tx.id);
    if (i != -1) _transactions[i] = tx;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<CategoryModel> addCategory({required String name, required String emoji, required Color color}) async {
    final cat = CategoryModel(id: _uuid.v4(), name: name, emoji: emoji, color: color);
    await _db.insertCategory(cat);
    _categories.add(cat);
    notifyListeners();
    return cat;
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void setFilterPeriod(FilterPeriod period) {
    _filterPeriod = period;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getMonthlyChartData() async {
    return await _db.getMonthlyTotals(DateTime.now().year);
  }

  Future<List<Map<String, dynamic>>> getDailyChartData() async {
    final now = DateTime.now();
    return await _db.getDailyTotals(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
  }
}
