import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'indicator_configs.dart';
import 'indicator_detail_sheets.dart';
import 'live_style.dart';

/// Numeric param row (integer or decimal; decimals for SAR step / channel multiplier /
/// BOLL std-dev multiplier).
Widget numParamRow(String label, num value, bool isInt, ValueChanged<num> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 140,
          height: 36,
          child: TextFormField(
            key: ValueKey('$label$value'),
            initialValue: isInt ? value.toInt().toString() : value.toString(),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
            style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: LiveStyle.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (t) {
              final v = parseIndicatorParam(t);
              // Integer periods round and must be >= 1; decimal multipliers must be positive.
              if (v == null || v <= 0) return;
              if (!isInt) return onChanged(v);
              if (v.round() >= 1) onChanged(v.round());
            },
          ),
        ),
      ],
    ),
  );
}

Widget lineColorHeader() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        Text(
          S.current.indicatorLine,
          style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary),
        ),
        const Spacer(),
        Text(
          S.current.indicatorColor,
          style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary),
        ),
      ],
    ),
  );
}

Widget paramRow(String label, int value, ValueChanged<int> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        numField(
          width: 140,
          value: value,
          onChanged: (v) {
            if (v != null && v > 0) onChanged(v);
          },
        ),
      ],
    ),
  );
}

Widget colorRow(String label, Color color, ValueChanged<Color> onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        colorDropdown(color, onChanged),
      ],
    ),
  );
}

/// Gray right-aligned number input (value/period).
Widget numField({
  required double width,
  required int? value,
  required ValueChanged<int?> onChanged,
}) {
  return SizedBox(
    width: width,
    height: 36,
    child: TextFormField(
      key: ValueKey('$value'),
      initialValue: value?.toString() ?? '',
      textAlign: TextAlign.right,
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: LiveStyle.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      // Empty clears this line's period; 0 and negatives are not submitted.
      onFieldSubmitted: (s) {
        final v = int.tryParse(s.trim());
        if (s.trim().isEmpty || (v != null && v > 0)) onChanged(v);
      },
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (s) {
        final v = int.tryParse(s);
        if (v != null && v > 0) onChanged(v);
      },
    ),
  );
}

/// Gray swatch dropdown (color column).
Widget colorDropdown(Color color, ValueChanged<Color> onChanged) {
  Widget swatch(Color c) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  // Must still show the current color when it's not in the palette (customized).
  final items = kIndicatorPalette.contains(color)
      ? kIndicatorPalette
      : [color, ...kIndicatorPalette];

  return Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: LiveStyle.inputFill,
      borderRadius: BorderRadius.circular(6),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Color>(
        value: color,
        icon: Icon(Icons.arrow_drop_down, size: 18, color: LiveStyle.textSecondary),
        items: [
          for (final c in items) DropdownMenuItem(value: c, child: swatch(c)),
        ],
        onChanged: (c) {
          if (c != null) onChanged(c);
        },
      ),
    ),
  );
}
