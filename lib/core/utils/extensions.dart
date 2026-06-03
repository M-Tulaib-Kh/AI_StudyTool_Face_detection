// ignore: unused_import
import 'package:flutter/material.dart';

extension StringX on String {
  String get capitalised =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}

extension DateX on DateTime {
  bool get isToday {
    final n = DateTime.now();
    return year == n.year && month == n.month && day == n.day;
  }

  String get friendlyDate {
    // ignore: unused_local_variable
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
      'Dec'
    ];
    return '\$day \${months[month-1]} \$year';
  }
}

extension IntX on int {
  String get secondsToHMS {
    // ignore: unused_local_variable
    final h = this ~/ 3600;
    // ignore: unused_local_variable
    final m = (this % 3600) ~/ 60;
    // ignore: unused_local_variable
    final s = this % 60;
    if (h > 0) return '\${h}h \${m}m';
    return '\${m}m \${s}s';
  }

  String get secondsToMSDisplay {
    // ignore: unused_local_variable
    final m = this ~/ 60;
    // ignore: unused_local_variable
    final s = this % 60;
    return '\${m.toString().padLeft(2,"0")}:\${s.toString().padLeft(2,"0")}';
  }
}
