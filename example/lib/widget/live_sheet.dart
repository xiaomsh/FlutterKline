import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'live_style.dart';
import 'pro_lock.dart';

/// Shared rounded bottom sheet (chart settings / indicator settings / more settings):
/// wraps a StatefulBuilder; the builder gets setSheet for local refreshes.
Future<void> showLiveSheet(
  BuildContext context,
  Widget Function(BuildContext ctx, StateSetter setSheet) builder, {
  bool scrollable = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: LiveStyle.bgPrimary,
    isScrollControlled: scrollable,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        final child = SafeArea(child: builder(ctx, setSheet));
        if (!scrollable) return child;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: SingleChildScrollView(child: child),
        );
      },
    ),
  );
}

/// Detail-style header: back arrow + centered title + optional "Reset" at the top right.
class LiveSheetHeader extends StatelessWidget {
  const LiveSheetHeader({super.key, required this.title, this.onReset});

  final String title;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18, color: LiveStyle.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: LiveStyle.textPrimary,
              ),
            ),
          ),
          if (onReset != null)
            InkWell(
              onTap: onReset,
              child: Text(
                S.current.commonReset,
                style: TextStyle(fontSize: 14, color: LiveStyle.brand),
              ),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }
}

/// Root sheet title bar: bold title on the left + round close button on the right.
class LiveSheetTitleBar extends StatelessWidget {
  const LiveSheetTitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LiveStyle.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: LiveStyle.inputFill,
            child: Icon(Icons.close, size: 14, color: LiveStyle.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Section title inside a sheet.
class LiveSectionTitle extends StatelessWidget {
  const LiveSectionTitle(this.title, {super.key, this.locked = false});

  final String title;

  /// Paid feature: shows a lock after the title
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LiveStyle.textPrimary,
            ),
          ),
          if (locked) const SizedBox(width: 4),
          if (locked) const ProLockIcon(),
        ],
      ),
    );
  }
}

/// Check row: square checkbox + text.
class LiveCheckRow extends StatelessWidget {
  const LiveCheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: LiveStyle.brand,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => onChanged(v ?? false),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: LiveStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
