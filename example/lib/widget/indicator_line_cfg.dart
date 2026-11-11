import 'package:flutter/material.dart';

/// One toggleable moving-average line config (a row in the MA/EMA detail sheet).
class LineCfg {
  bool on;
  int? period;
  Color color;

  LineCfg({this.on = false, this.period, required this.color});
}
