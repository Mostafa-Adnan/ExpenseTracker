import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'expense_tracker.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: _onCreate,
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw Exception('Database timeout'),
  );
}

  Future<void> _onCreate(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        color INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert default categories
    for (final cat in CategoryModel.defaults) {
      await db.insert('categories', cat.toMap());
    }
  }

  // ─── TRANSACTIONS ────────────────────────────────────────────────────────

  Future<String> insertTransaction(TransactionModel tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return tx.id;
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC, createdAt DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
      DateTime from, DateTime to) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'title LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<Map<String, double>> getCategoryTotals(
      {TransactionType? type, DateTime? from, DateTime? to}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];

    List<String> conditions = [];
    if (type != null) {
      conditions.add('type = ?');
      args.add(type.name);
    }
    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.toIso8601String());
    }
    if (conditions.isNotEmpty) {
      where = 'WHERE ${conditions.join(' AND ')}';
    }

    final result = await db.rawQuery(
        'SELECT categoryId, SUM(amount) as total FROM transactions $where GROUP BY categoryId',
        args);

    return {
      for (var row in result)
        row['categoryId'] as String: (row['total'] as num).toDouble()
    };
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(
      DateTime from, DateTime to) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        substr(date, 1, 10) as day,
        type,
        SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY day, type
      ORDER BY day ASC
    ''', [from.toIso8601String(), to.toIso8601String()]);
    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals(int year) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        substr(date, 1, 7) as month,
        type,
        SUM(amount) as total
      FROM transactions
      WHERE substr(date, 1, 4) = ?
      GROUP BY month, type
      ORDER BY month ASC
    ''', [year.toString()]);
    return result;
  }

  // ─── CATEGORIES ──────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<String> insertCategory(CategoryModel cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return cat.id;
  }

  Future<int> updateCategory(CategoryModel cat) async {
    final db = await database;
    return await db.update(
      'categories',
      cat.toMap(),
      where: 'id = ?',
      whereArgs: [cat.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
