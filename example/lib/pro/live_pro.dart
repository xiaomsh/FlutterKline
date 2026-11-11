import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:klinex/klinex.dart';

import '../l10n/l10n.dart';
import '../page/live/live_controller.dart';
import '../page/setting/sample/sample_entry.dart';
import '../widget/pro_lock.dart';

/// Paid-edition entry points of the live page. In the free edition all are locked stubs: entries
/// still show, and tapping them shows the "paid feature" prompt
class LivePro {
  LivePro(this.page);

  static const bool unlocked = false;

  /// Paid-edition samples in the settings catalog; all locked placeholders in the free edition
  static List<SampleEntry> settingSamples() => [
    SampleEntry.locked(
      id: 'transforms',
      category: SampleCategory.data,
      title: () => S.current.proSampleTransforms,
      keywords: const ['renko', 'kagi', 'pointFigure', 'Resampler'],
    ),
    SampleEntry.locked(
      id: 'pro-indicators',
      category: SampleCategory.indicators,
      title: () => S.current.proSampleIndicators,
      keywords: const ['IndicatorRegistry'],
    ),
    for (final (id, title) in [
      ('drawing', () => S.current.proSampleDrawing),
      ('orders', () => S.current.proSampleOrders),
      ('alerts', () => S.current.proSampleAlerts),
      ('fills', () => S.current.proSampleFills),
      ('position', () => S.current.proSamplePosition),
      ('replay', () => S.current.proSampleReplay),
      ('sync', () => S.current.proSampleSync),
      ('compare', () => S.current.proSampleCompare),
    ])
      SampleEntry.locked(id: id, category: SampleCategory.pro, title: title),
  ];

  static const mainOptions = [
    'WMA', 'SAR', 'ST', 'KC', 'DC', 'VWAP', 'ICHI', 'VP', 'DEMA', 'TEMA', 'HMA', 'VWMA', //
    'KAMA', 'ALMA', 'LSMA', 'PIVOT', 'ZIGZAG', //
  ];

  static const subOptions = [
    'StochRSI', 'CCI', 'OBV', 'ATR', 'DMI', 'MFI', 'CMF', 'ROC', 'MTM', 'TRIX', //
    'STOCH', 'AROON', 'STD', 'HV', 'AD', 'CHO', //
    '%B', 'BBW', 'VORTEX', 'CHOP', 'AO', 'PPO', 'FISHER', //
  ];

  static Map<String, String> get seriesNames => {
    'ohlc': S.current.proSeriesOhlc,
    'volCandle': S.current.proSeriesVolCandle,
    'markers': S.current.proSeriesMarkers,
    'step': S.current.proSeriesStep,
    'hlcArea': S.current.proSeriesHlcArea,
    'baseline': S.current.proSeriesBaseline,
    'column': S.current.proSeriesColumn,
    'hiLo': S.current.proSeriesHiLo,
  };

  static MainSeries? seriesOf(String kind) => null;

  static List<Bar> toHeikinAshi(List<Bar> bars) => bars;

  static Bar nextHeikinAshi(Bar raw, Bar? prev) => raw;

  final LiveController page;

  final heikinAshi = false.obs;

  // ---- Indicators ----

  List<Indicator> buildIndicators(Set<String> main, Set<String> sub) => const [];

  List<Widget> indicatorItems(
    BuildContext context,
    VoidCallback onChanged,
    Widget Function(String title) group,
    Widget Function(String name, String desc, VoidCallback onTap, {bool locked}) item,
    void Function(Future<void> Function() open) goto,
  ) {
    final s = S.current;
    return [
      group(s.proGroupMain),
      item('WMA', s.proIndicatorWma, showProLock, locked: true),
      item('SAR', s.proIndicatorSar, showProLock, locked: true),
      item('ST', s.proIndicatorSt, showProLock, locked: true),
      item('KC', s.proIndicatorKc, showProLock, locked: true),
      item('DC', s.proIndicatorDc, showProLock, locked: true),
      item('ICHI', s.proIndicatorIchi, showProLock, locked: true),
      item('DEMA', s.proIndicatorDema, showProLock, locked: true),
      item('TEMA', s.proIndicatorTema, showProLock, locked: true),
      item('HMA', s.proIndicatorHma, showProLock, locked: true),
      item('VWMA', s.proIndicatorVwma, showProLock, locked: true),
      item('KAMA', s.proIndicatorKama, showProLock, locked: true),
      item('ALMA', s.proIndicatorAlma, showProLock, locked: true),
      item('LSMA', s.proIndicatorLsma, showProLock, locked: true),
      item('PIVOT', s.proIndicatorPivot, showProLock, locked: true),
      item('ZIGZAG', s.proIndicatorZigzag, showProLock, locked: true),
      group(s.proGroupSub),
      item('CCI', s.proIndicatorCci, showProLock, locked: true),
      item('OBV', s.proIndicatorObv, showProLock, locked: true),
      item('StochRSI', s.proIndicatorStochRsi, showProLock, locked: true),
      item('ATR', s.proIndicatorAtr, showProLock, locked: true),
      item('DMI', s.proIndicatorDmi, showProLock, locked: true),
      item('MFI', s.proIndicatorMfi, showProLock, locked: true),
      item('CMF', s.proIndicatorCmf, showProLock, locked: true),
      item('ROC', s.proIndicatorRoc, showProLock, locked: true),
      item('MTM', s.proIndicatorMtm, showProLock, locked: true),
      item('TRIX', s.proIndicatorTrix, showProLock, locked: true),
      item('STOCH', s.proIndicatorStoch, showProLock, locked: true),
      item('AROON', s.proIndicatorAroon, showProLock, locked: true),
      item('STD', s.proIndicatorStd, showProLock, locked: true),
      item('HV', s.proIndicatorHv, showProLock, locked: true),
      item('AD', s.proIndicatorAd, showProLock, locked: true),
      item('CHO', s.proIndicatorCho, showProLock, locked: true),
      item('%B', s.proIndicatorPercentB, showProLock, locked: true),
      item('BBW', s.proIndicatorBbw, showProLock, locked: true),
      item('VORTEX', s.proIndicatorVortex, showProLock, locked: true),
      item('CHOP', s.proIndicatorChop, showProLock, locked: true),
      item('AO', s.proIndicatorAo, showProLock, locked: true),
      item('PPO', s.proIndicatorPpo, showProLock, locked: true),
      item('FISHER', s.proIndicatorFisher, showProLock, locked: true),
    ];
  }

  // ---- Locked entries ----

  void setHeikinAshi(bool v) => showProLock();
}
