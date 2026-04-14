import 'package:flutter/material.dart';

class LogEntry {
  final String section;
  final String msg;
  final IconData icon;
  final Color color;
  final TimeOfDay time;

  const LogEntry({
    required this.section,
    required this.msg,
    required this.icon,
    required this.color,
    required this.time,
  });
}
