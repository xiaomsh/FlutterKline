import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'live_style.dart';

/// Interval bar: the first [showCount] are laid out flat, the rest go into "More";
/// when the selected one is in "More", that slot shows the selected interval
class LiveIntervalBar extends StatefulWidget {
  const LiveIntervalBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.intervals = liveSortedIntervals,
    this.showCount = 5,
    this.height = 30,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final List<String> intervals;

  /// Number laid out flat; null means all flat with no "More".
  final int? showCount;
  final double height;

  @override
  State<LiveIntervalBar> createState() => _LiveIntervalBarState();
}

class _LiveIntervalBarState extends State<LiveIntervalBar> {
  final GlobalKey _barKey = GlobalKey();
  bool _isMoreOpen = false;

  /// Number laid out flat. Must be clamped to [0, intervals.length], otherwise sublist below
  /// throws RangeError when showCount exceeds the total.
  int get _flatCount =>
      (widget.showCount ?? widget.intervals.length).clamp(0, widget.intervals.length);

  List<String> get _shown => widget.intervals.take(_flatCount).toList();

  List<String> get _more => widget.intervals.sublist(_flatCount);

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final more = _more;
    final selectedInMore = more.contains(widget.selected);

    return SizedBox(
      key: _barKey,
      height: widget.height,
      // Scroll horizontally in narrow windows instead of overflowing
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final iv in shown) _item(iv),
            if (more.isNotEmpty) _moreButton(selectedInMore),
          ],
        ),
      ),
    );
  }

  Widget _item(String interval) {
    final selected = interval == widget.selected;
    return InkWell(
      onTap: () => widget.onSelected(interval),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: selected
            ? BoxDecoration(
                color: LiveStyle.inputFill,
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        child: Text(
          intervalLabel(interval),
          style: TextStyle(
            fontSize: 13,
            color: selected ? LiveStyle.textPrimary : LiveStyle.textSecondary,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _moreButton(bool selectedInMore) {
    final highlight = selectedInMore || _isMoreOpen;
    return InkWell(
      onTap: _showMorePanel,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: selectedInMore
            ? BoxDecoration(
                color: LiveStyle.inputFill,
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedInMore ? intervalLabel(widget.selected) : S.current.liveIntervalMore,
              style: TextStyle(
                fontSize: 13,
                color: highlight ? LiveStyle.textPrimary : LiveStyle.textSecondary,
                fontWeight: selectedInMore ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            Icon(
              _isMoreOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: highlight ? LiveStyle.textPrimary : LiveStyle.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMorePanel() async {
    setState(() => _isMoreOpen = true);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        // Measure the anchor in the builder: it reads MediaQuery, so rotation reruns it and the
        // position and column count follow
        final isPortrait = MediaQuery.of(ctx).orientation == Orientation.portrait;
        final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
        final top = box == null || !box.attached
            ? 100.0
            : box.localToGlobal(Offset.zero).dy + box.size.height;
        return Stack(
          children: [
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: Material(
                color: LiveStyle.bgPrimary,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isPortrait ? 4 : 6,
                    childAspectRatio: isPortrait ? 3 : 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (final iv in _more)
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onSelected(iv);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: iv == widget.selected
                                  ? LiveStyle.brandAlert
                                  : LiveStyle.inputFill,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              intervalLabel(iv),
                              style: TextStyle(
                                fontSize: 13,
                                color: iv == widget.selected
                                    ? LiveStyle.brand
                                    : LiveStyle.textPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (mounted) setState(() => _isMoreOpen = false);
  }
}
