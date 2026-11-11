import 'package:klinex/klinex.dart';

import '../l10n/l10n.dart';
import '../page/setting/sample/sample_entry.dart';

/// Paid-edition stock features (five-day intraday, price adjustment). In the free edition they
/// are locked stubs: entries still show, and tapping them shows the "paid feature" prompt
class StockPro {
  static const bool unlocked = false;

  /// Paid-edition stock samples in the settings catalog
  static List<SampleEntry> settingSamples() => [
    SampleEntry.locked(
      id: 'five-day',
      category: SampleCategory.stocks,
      title: () => S.current.proSampleFiveDay,
      keywords: const ['MultiDayAxis', 'fiveDay'],
    ),
    SampleEntry.locked(
      id: 'adjust',
      category: SampleCategory.stocks,
      title: () => S.current.proSampleAdjust,
      keywords: const ['PriceAdjuster', 'AdjustMode'],
    ),
  ];

  /// Slot axis spanning several trading [days] (exchange days since epoch); null when locked
  static SlotAxis? multiDayAxis(TradingSession session, List<int> days) => null;
}
