import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'indicator.dart';

/// The currently attached indicators. Every add/remove bumps [generation] and notifies.
class IndicatorSet extends ChangeNotifier {
  final List<Indicator> _list = [];
  late final List<Indicator> _view = UnmodifiableListView(_list);
  int _generation = 0;

  int get generation => _generation;

  /// Read-only; mutate via [setAll] / [add] / [remove], otherwise generation and
  /// notifications get out of sync.
  List<Indicator> get list => _view;

  void setAll(List<Indicator> indicators) {
    _list
      ..clear()
      ..addAll(dedupeById(indicators));
    _bump();
  }

  /// Replaces in place if the id already exists (last wins): two copies would share one
  /// store, drawing the legend twice and overwriting each other's results.
  void add(Indicator indicator) {
    final i = _list.indexWhere((e) => e.id == indicator.id);
    if (i >= 0) {
      assert(_warnDuplicate(indicator.id));
      _list[i] = indicator;
    } else {
      _list.add(indicator);
    }
    _bump();
  }

  void remove(String id) {
    _list.removeWhere((e) => e.id == id);
    _bump();
  }

  /// Dedupes by id, last wins like [add]: keeps the first occurrence's position with the
  /// last occurrence's content.
  static List<Indicator> dedupeById(List<Indicator> indicators) {
    final at = <String, int>{};
    final out = <Indicator>[];
    for (final ind in indicators) {
      final i = at[ind.id];
      if (i == null) {
        at[ind.id] = out.length;
        out.add(ind);
      } else {
        assert(_warnDuplicate(ind.id));
        out[i] = ind;
      }
    }
    return out;
  }

  static bool _warnDuplicate(String id) {
    debugPrint('klinex IndicatorSet: duplicate indicator id "$id", merged into one (last wins)');
    return true;
  }

  void _bump() {
    _generation++;
    notifyListeners();
  }
}
