/// An immutable candlestick bar. [vol]'s unit is up to the host (coin amount or turnover);
/// the chart just draws it.
class Bar {
  final int time; // Timestamp in milliseconds
  final double open, high, low, close, vol;

  const Bar({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.vol = 0,
  });

  bool get isUp => close >= open;

  Bar copyWith({
    int? time,
    double? open,
    double? high,
    double? low,
    double? close,
    double? vol,
  }) {
    return Bar(
      time: time ?? this.time,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      vol: vol ?? this.vol,
    );
  }

  @override
  String toString() => 'Bar($time o:$open h:$high l:$low c:$close v:$vol)';
}
