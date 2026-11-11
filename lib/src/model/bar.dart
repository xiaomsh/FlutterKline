/// An immutable candlestick bar. [vol]'s unit is up to the host (coin amount, shares or lots);
/// the chart just draws it.
class Bar {
  final int time; // Timestamp in milliseconds
  final double open, high, low, close, vol;

  /// Turnover (price × volume, in money). Optional: when set, the average price line uses it
  /// instead of estimating from close × [vol].
  final double? amount;

  const Bar({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.vol = 0,
    this.amount,
  });

  bool get isUp => close >= open;

  Bar copyWith({
    int? time,
    double? open,
    double? high,
    double? low,
    double? close,
    double? vol,
    double? amount,
  }) {
    return Bar(
      time: time ?? this.time,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      vol: vol ?? this.vol,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() =>
      'Bar($time o:$open h:$high l:$low c:$close v:$vol${amount == null ? '' : ' a:$amount'})';
}

/// Sum of two optional amounts: null only when both are null.
double? addAmount(double? a, double? b) => a == null && b == null ? null : (a ?? 0) + (b ?? 0);
