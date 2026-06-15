import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat('#,##0.##', 'ar');
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'ar');
  static final _shortDateFormat = DateFormat('dd MMM', 'ar');
  static final _monthFormat = DateFormat('MMMM yyyy', 'ar');
  static final _timeFormat = DateFormat('hh:mm a', 'ar');

  static String currency(double amount, {String symbol = 'د.ع'}) {
    return '${_currencyFormat.format(amount)} $symbol';
  }

  static String date(DateTime dt) => _dateFormat.format(dt);
  static String shortDate(DateTime dt) => _shortDateFormat.format(dt);
  static String month(DateTime dt) => _monthFormat.format(dt);
  static String time(DateTime dt) => _timeFormat.format(dt);

  static String relativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return _dateFormat.format(dt);
  }

  static String compact(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}م';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}ك';
    }
    return amount.toStringAsFixed(0);
  }
}
