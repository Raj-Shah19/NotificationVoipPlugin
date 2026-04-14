import 'package:flutter/material.dart';

import 'log_controller.dart';

class MiniLog extends StatelessWidget {
  final String section;
  final LogController logController;

  const MiniLog({
    super.key,
    required this.section,
    required this.logController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logController,
      builder: (context, _) {
        final entries = logController.entriesFor(section);
        if (entries.isEmpty) return const SizedBox.shrink();
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    const Icon(Icons.terminal, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Output (${entries.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => logController.clearSection(section),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...entries.take(15).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(entry.icon, color: entry.color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.msg,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Text(
                            entry.time.format(context),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
