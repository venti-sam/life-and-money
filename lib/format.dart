/// 1234.5 -> "1,234.50"
String money(double v) {
  final negative = v < 0;
  final parts = v.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '${negative ? '-' : ''}$whole.${parts[1]}';
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];

/// "2026-09" -> "September 2026"
String monthLabel(String month) =>
    '${_monthNames[int.parse(month.substring(5, 7)) - 1]} ${month.substring(0, 4)}';
