import 'package:flutter/material.dart';
import 'package:klinex/klinex.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widget/axis_price_tags.dart';
import '../../sample/sample_view.dart';
import '../../widgets/controls.dart';

/// Last price line, y-axis price tags (last price / countdown / bid-ask), price animation and
/// visible high / low labels.
class PriceLineSample extends SampleView {
  const PriceLineSample({super.key});
  @override
  State<PriceLineSample> createState() => _PriceLineSampleState();
}

class _PriceLineSampleState extends SampleViewState<PriceLineSample>
    with SampleFeedMixin<PriceLineSample> {
  static const _pushEvery = Duration(milliseconds: 600);

  final _priceLine = PriceLineOverlay();
  bool _showPrice = true, _countdown = true, _book = true;
  bool _animatePrice = true, _animateRange = false, _highLow = true;
  _PriceType _priceType = _PriceType.last;

  @override
  ChartController createController() => ChartController(indicators: [Ma()], overlays: [_priceLine]);

  @override
  void initState() {
    super.initState();
    feed.autoPush(_pushEvery);
  }

  @override
  Widget buildChart(BuildContext context) => frame(
    KChart(
      controller: controller,
      theme: chartTheme,
      labels: chartLabels,
      animatePrice: _animatePrice,
      animateRange: _animateRange,
      showHighLow: _highLow,
      overlayBuilder: (_, ctx) {
        if (ctx.bars.isEmpty) return const SizedBox.shrink();
        final last = ctx.bars.last;
        final bar = feed.barDuration;
        // Base the simulated book on the displayed (animated) price, otherwise the bid would rise
        // above the last price during the 200 ms animation
        final mid = ctx.controller.animatedLastClose.value ?? last.close;
        final tip = _priceType.tip;
        return Stack(
          children: [
            AxisPriceTags(
              ctx: ctx,
              showPrice: _showPrice,
              showCountdown: _countdown && bar != null,
              periodMs: bar?.inMilliseconds,
              // Synthetic timestamps are not current: last bar open + real time since its append
              now: () => last.time + feed.msSinceBarOpen,
              book: _book ? (bid: mid - 0.03, ask: mid + 0.02) : null,
            ),
            if (tip != null)
              Positioned(
                left: ctx.chartRect.left + 8,
                top: ctx.mainPanel.rect.bottom - 18,
                child: IgnorePointer(
                  child: Text(tip, style: TextStyle(fontSize: 10, color: ctx.theme.axisText)),
                ),
              ),
          ],
        );
      },
    ),
  );

  @override
  List<Widget> buildSettings(BuildContext context) => [
    Toggle(S.current.priceLineShowPrice, _showPrice, (v) {
      update(() => _showPrice = v);
      _priceLine.showPrice = v;
    }),
    Toggle(S.current.priceLineCountdown, _countdown, (v) => update(() => _countdown = v)),
    Toggle(S.current.priceLineBook, _book, (v) => update(() => _book = v)),
    Choice(S.current.priceLinePriceType, _priceType, {
      for (final t in _PriceType.values) t: t.label,
    }, (v) => update(() => _priceType = v)),
    Text(S.current.priceLinePriceTypeHint),
    Toggle(S.current.priceLineAnimatePrice, _animatePrice, (v) => update(() => _animatePrice = v)),
    Toggle(S.current.priceLineAnimateRange, _animateRange, (v) => update(() => _animateRange = v)),
    Toggle(S.current.priceLineHighLow, _highLow, (v) => update(() => _highLow = v)),
    Toggle(S.current.sampleAutoPush, feed.pushing, (v) => feed.autoPush(v ? _pushEvery : null)),
    Text(S.current.priceLineOverlayHint),
    Text(S.current.priceLineTagsHint),
    Text(S.current.priceLineStackHint),
    Text(S.current.priceLineDataHint),
    Text(S.current.priceLineAnimateHint),
  ];

  @override
  String code() =>
      'final priceLine = PriceLineOverlay()..showPrice = $_showPrice;\n'
      'final controller = ChartController(overlays: [priceLine]);\n'
      'KChart(controller: controller, animatePrice: $_animatePrice,\n'
      '  animateRange: $_animateRange, showHighLow: $_highLow,\n'
      '  overlayBuilder: (_, ctx) => AxisPriceTags(\n'
      '    ctx: ctx, showPrice: $_showPrice, showCountdown: $_countdown,\n'
      '    book: ${_book ? '(bid: bid, ask: ask)' : 'null'},\n'
      '  ),\n'
      ')';
}

enum _PriceType {
  last,
  mark,
  indexPrice;

  String get label => switch (this) {
    last => S.current.priceLineTypeLast,
    mark => S.current.priceLineTypeMark,
    indexPrice => S.current.priceLineTypeIndex,
  };

  String? get tip => switch (this) {
    last => null,
    mark => S.current.priceLineTipMark,
    indexPrice => S.current.priceLineTipIndex,
  };
}
