import 'package:flutter/material.dart';

import 'log_entry.dart';

/// Shared log controller that sections can use to add/read logs.
class LogController extends ChangeNotifier {
  final List<LogEntry> _entries = [];
  static const _maxEntries = 200;

  List<LogEntry> get entries => List.unmodifiable(_entries);

  List<LogEntry> entriesFor(String section) =>
      _entries.where((e) => e.section == section).toList();

  void add(String section, String msg, IconData icon, Color color) {
    _entries.insert(
      0,
      LogEntry(
        section: section,
        msg: msg,
        icon: icon,
        color: color,
        time: TimeOfDay.now(),
      ),
    );
    if (_entries.length > _maxEntries) _entries.removeLast();
    notifyListeners();
  }

  void clearSection(String section) {
    _entries.removeWhere((e) => e.section == section);
    notifyListeners();
  }

  void clearAll() {
    _entries.clear();
    notifyListeners();
  }
}
