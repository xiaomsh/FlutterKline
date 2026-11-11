import 'package:flutter/material.dart';

import 'live_style.dart';
import 'pro_lock.dart';

/// Indicator multi-select (like flutter_app's MultiSelectorTabWidget): a row below the chart;
/// tap to toggle.
class IndicatorSelector extends StatelessWidget {
  const IndicatorSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.locked = const {},
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  /// Pro indicators, shown with a lock after the name.
  final Set<String> locked;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final name in options)
        InkWell(
          onTap: () => onToggle(name),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected.contains(name)
                        ? LiveStyle.textPrimary
                        : LiveStyle.textSecondary,
                    fontWeight: selected.contains(name) ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (locked.contains(name)) const ProLockIcon(size: 9),
              ],
            ),
          ),
        ),
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
