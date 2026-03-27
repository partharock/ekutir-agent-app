String currency(double amount) {
  final formatted = amount.toStringAsFixed(0);
  if (formatted.length <= 3) {
    return '₹$formatted';
  }

  final lastThree = formatted.substring(formatted.length - 3);
  var prefix = formatted.substring(0, formatted.length - 3);
  final groups = <String>[];

  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }

  if (prefix.isNotEmpty) {
    groups.insert(0, prefix);
  }

  return '₹${groups.join(',')},$lastThree';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${formatDate(dateTime)} • $hour:$minute';
}
