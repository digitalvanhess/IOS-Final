/// Small formatting helpers (no intl dependency needed yet).
class Format {
  static const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const _monthsShort = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  static const _monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  /// 78200 -> "78 200 ₸"
  static String money(num value, {bool withSign = false}) {
    final abs = value.abs().round();
    final digits = abs.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final sign = withSign ? (value < 0 ? '−' : '+') : (value < 0 ? '−' : '');
    return '$sign$buffer ₸';
  }

  /// "Ср, 7 окт"
  static String shortDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_monthsShort[date.month - 1]}';

  /// "1 ноября"
  static String dayMonth(DateTime date) =>
      '${date.day} ${_monthsGenitive[date.month - 1]}';

  /// "Сегодня", "Вчера" or "5 октября"
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final diff = today.difference(_dateOnly(date)).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    return dayMonth(date);
  }

  /// "14:05"
  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  /// 25 -> "дней", 1 -> "день", 3 -> "дня"
  static String daysWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'дня';
    }
    return 'дней';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
