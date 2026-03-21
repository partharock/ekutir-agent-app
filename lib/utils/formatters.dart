import 'package:flutter/material.dart';

String currency(double amount) {
  final formatted = amount.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < formatted.length; i++) {
    final positionFromEnd = formatted.length - i;
    buffer.write(formatted[i]);
    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '₹$buffer';
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
