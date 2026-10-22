final _amountRe = RegExp(r'^-?\d{1,3}(,\d{3})*\.\d{2}$|^-?\d+\.\d{2}$');

bool isAmount(String s) => _amountRe.hasMatch(s.trim());

/// "1,234.50" -> 1234.5, or null if it isn't an amount.
double? parseAmount(String s) {
  final t = s.trim();
  if (!isAmount(t)) return null;
  return double.parse(t.replaceAll(',', ''));
}

double round2(double v) => (v * 100).roundToDouble() / 100;

const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

int? monthNumber(String abbreviation) =>
    _months[abbreviation.toLowerCase().substring(0, 3)];

String isoDate(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

/// "30 Sep 2026" -> "2026-09-30", or null.
String? parseLongDate(String s) {
  final m = RegExp(r'(\d{1,2}) ([A-Za-z]{3})[A-Za-z]* (\d{4})').firstMatch(s);
  if (m == null) return null;
  final month = monthNumber(m.group(2)!);
  if (month == null) return null;
  return isoDate(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
}
