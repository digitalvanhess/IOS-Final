import 'expense.dart';

/// Stipend budget. The daily limit is the money left at the start of the
/// day divided by the days left until the next stipend.
class Budget {
  final int balanceAtDayStart;
  final DateTime nextStipendDate;

  const Budget({
    required this.balanceAtDayStart,
    required this.nextStipendDate,
  });

  int daysLeft(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final days = nextStipendDate.difference(today).inDays;
    return days < 1 ? 1 : days;
  }

  int dailyLimit(DateTime now) => balanceAtDayStart ~/ daysLeft(now);

  int spentToday(List<Expense> expenses, DateTime now) => expenses
      .where(
        (e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day,
      )
      .fold(0, (sum, e) => sum + e.amount);

  int leftToday(List<Expense> expenses, DateTime now) =>
      dailyLimit(now) - spentToday(expenses, now);

  int remaining(List<Expense> expenses, DateTime now) =>
      balanceAtDayStart - spentToday(expenses, now);
}
