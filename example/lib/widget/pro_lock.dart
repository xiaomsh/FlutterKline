import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../l10n/l10n.dart';
import 'live_style.dart';

/// Small lock next to Pro features.
class ProLockIcon extends StatelessWidget {
  const ProLockIcon({super.key, this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.lock_outline, size: size, color: LiveStyle.textTertiary);
  }
}

/// A locked feature was tapped.
void showProLock() {
  SmartDialog.showToast(S.current.proLockFeature);
}
