import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widget/indicator_detail_sheets.dart';

class ParameterInput extends StatefulWidget {
  const ParameterInput(this.param, this.onChanged, {super.key});
  final ParamSpec param;
  final VoidCallback onChanged;
  @override
  State<ParameterInput> createState() => _ParameterInputState();
}

class _ParameterInputState extends State<ParameterInput> {
  late final text = TextEditingController(text: '${widget.param.get()}');
  late num _model = widget.param.get();

  @override
  void didUpdateWidget(ParameterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final p = widget.param;
    if (_model != p.get()) text.text = '${p.get()}';
    _model = p.get();
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: text,
      decoration: InputDecoration(
        labelText: widget.param.label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: !widget.param.isInt),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (input) => _valid(input ?? '') == null
          ? (widget.param.isInt ? S.current.paramInputIntError : S.current.paramInputNumberError)
          : null,
      onChanged: (input) {
        final value = _valid(input);
        if (value == null) return;
        widget.param.set(widget.param.isInt ? value.toInt() : value);
        _model = widget.param.get();
        widget.onChanged();
      },
    ),
  );

  num? _valid(String text) {
    final value = parseIndicatorParam(text);
    return value == null || (widget.param.isInt && value != value.round()) ? null : value;
  }
}
