import '../render/slot_axis.dart';
import 'trading_session.dart';

/// Builds the ticks of one trading day starting at slot [offset]: the open, every [stepMinutes]
/// from each segment's open, breaks as one combined label (`11:30/13:00`), and the close.
/// [openLabel] replaces the open's label (e.g. a date on multi-day axes).
List<SlotTick> sessionDayTicks(
  TradingSession session, {
  int offset = 0,
  int stepMinutes = 60,
  String? openLabel,
  bool openMajor = false,
}) {
  final fmt = TradingSession.formatMinute;
  final segs = session.segments;
  final ticks = <SlotTick>[];
  for (var k = 0; k < segs.length; k++) {
    final (open, close) = segs[k];
    if (k == 0) {
      ticks.add(
        SlotTick(offset + session.slotAtMinute(open), openLabel ?? fmt(open), major: openMajor),
      );
    } else {
      final prevClose = segs[k - 1].$2;
      ticks.add(
        SlotTick(offset + session.slotAtMinute(prevClose), '${fmt(prevClose)}/${fmt(open)}'),
      );
    }
    for (var m = open + stepMinutes; m < close; m += stepMinutes) {
      ticks.add(SlotTick(offset + session.slotAtMinute(m), fmt(m)));
    }
  }
  final close = segs.last.$2;
  ticks.add(SlotTick(offset + session.slotAtMinute(close), fmt(close)));
  return ticks;
}

/// One-day intraday time axis: one slot per minute of [session] (A-share 241, HK 331, US 391),
/// labeled at the open, every [stepMinutes], the lunch break and the close. Equal axes don't
/// relayout the chart, so it can be created inline in `build`.
class IntradayAxis extends SlotAxis {
  IntradayAxis(this.session, {this.stepMinutes = 60});

  final TradingSession session;
  final int stepMinutes;

  @override
  int get slotCount => session.slotsPerDay;

  @override
  late final List<SlotTick> ticks = sessionDayTicks(session, stepMinutes: stepMinutes);

  @override
  bool operator ==(Object other) =>
      other is IntradayAxis && other.session == session && other.stepMinutes == stepMinutes;

  @override
  int get hashCode => Object.hash(session, stepMinutes);
}
