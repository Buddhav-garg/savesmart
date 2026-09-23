/// Money is always stored as an int in paise inside SaveSmart.
/// These helpers are the only place we convert to and from rupees.
library;

/// 1234567890 -> '₹1,23,45,678.90'
String formatRupees(int paise, {bool showSign = false}) {
  final isNegative = paise < 0;
  final absolute = paise.abs();
  final rupees = absolute ~/ 100;
  final paisePart = (absolute % 100).toString().padLeft(2, '0');
  final sign = isNegative ? '-' : (showSign ? '+' : '');
  return '$sign₹${_indianGrouping(rupees.toString())}.$paisePart';
}

/// Indian grouping: last three digits, then groups of two (12,34,56,789).
String _indianGrouping(String digits) {
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$lastThree';
}

/// Parses user input such as '49.8' or '1,000' into paise without using
/// doubles. Returns null for anything that is not a valid amount.
int? parseRupeesToPaise(String input) {
  final text = input.trim().replaceAll(',', '');
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final rupees = int.parse(parts[0]);
  final paise = parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0;
  return rupees * 100 + paise;
}
