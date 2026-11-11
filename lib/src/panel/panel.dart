import '../indicator/indicator.dart';

/// Where an indicator draws: the main panel, a named sub-panel shared with other indicators (e.g.
/// VOL + MAVol both on 'vol'), or its own sub-panel.
class PanelRef {
  final String? _id;
  final bool _own;

  /// Draws on the main panel on the secondary value axis (own range, scale labels on the opposite
  /// side of the main scale).
  final bool isSecondaryAxis;

  const PanelRef._(this._id, this._own, [this.isSecondaryAxis = false]);

  static const PanelRef main = PanelRef._('main', false);

  /// Main secondary value axis: overlays things with different units than price (another symbol's
  /// price, RSI) on the main panel without squeezing the price range.
  static const PanelRef mainSecondary = PanelRef._('main', false, true);

  const PanelRef.named(String id) : this._(id, false);

  /// Each indicator instance gets its own sub-panel.
  const PanelRef.own() : this._(null, true);

  bool get isMain => !_own && _id == 'main';

  String keyFor(Indicator indicator) => _own ? 'own:${indicator.id}' : _id!;
}
