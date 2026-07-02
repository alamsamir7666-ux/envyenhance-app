/// Formats a numeric amount as Bangladeshi Taka, matching how prices are
/// shown across the EnvyEnhance website (৳ symbol, no decimals for whole
/// numbers since Taka isn't typically shown with paisa in retail UI).
String formatTaka(num amount) {
  final isWhole = amount == amount.roundToDouble();
  final value = isWhole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  // Insert thousands separators (South Asian lakh/crore grouping is
  // overkill for a skincare store's price range, so use standard grouping).
  final parts = value.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  final formattedInt = buffer.toString();
  return '৳$formattedInt${parts.length > 1 ? '.${parts[1]}' : ''}';
}

/// Relative-ish date formatting for order history / review timestamps.
String formatDate(String isoString) {
  try {
    final date = DateTime.parse(isoString).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return isoString;
  }
}
