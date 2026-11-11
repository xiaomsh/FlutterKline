import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../pro/live_pro.dart';
import 'indicator_configs.dart';
import 'indicator_detail_sheets.dart';
import 'live_sheet.dart';
import 'live_style.dart';
import 'pro_lock.dart';

/// Indicator settings entry: top-level list (main/sub groups, like flutter_app's indicator
/// settings page); tap an item for its detail. [onChanged] fires after any param change
/// (rebuilds indicators).
Future<void> showIndicatorSettings(
  BuildContext context,
  IndicatorConfigs cfg,
  LivePro pro,
  VoidCallback onChanged,
) {
  return showLiveSheet(
    context,
    (ctx, setSheet) {
      Widget group(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Text(title, style: TextStyle(fontSize: 13, color: LiveStyle.textTertiary)),
      );

      Widget item(String name, String desc, VoidCallback onTap, {bool locked = false}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: LiveStyle.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: LiveStyle.textPrimary),
                ),
              ),
              locked
                  ? const ProLockIcon()
                  : Icon(Icons.chevron_right, size: 18, color: LiveStyle.brand),
            ],
          ),
        ),
      );

      void goto(Future<void> Function() open) {
        Navigator.pop(ctx);
        open().then((_) {
          if (context.mounted) showIndicatorSettings(context, cfg, pro, onChanged);
        });
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveSheetHeader(title: S.current.indicatorSettingsTitle),
          group(S.current.indicatorGroupMain),
          item(
            'MA',
            S.current.indicatorMaDesc,
            () => goto(() => showLinesDetail(context, 'MA', cfg.maLines, cfg.resetMa, onChanged)),
          ),
          item(
            'EMA',
            S.current.indicatorEmaDesc,
            () =>
                goto(() => showLinesDetail(context, 'EMA', cfg.emaLines, cfg.resetEma, onChanged)),
          ),
          item(
            'BOLL',
            S.current.indicatorBollDesc,
            () => goto(() => showBollDetail(context, cfg, onChanged)),
          ),
          group(S.current.indicatorGroupSub),
          item(
            'MACD',
            S.current.indicatorMacdDesc,
            () => goto(() => showMacdDetail(context, cfg, onChanged)),
          ),
          item(
            'KDJ',
            S.current.indicatorKdjDesc,
            () => goto(() => showKdjDetail(context, cfg, onChanged)),
          ),
          item(
            'RSI',
            S.current.indicatorRsiDesc,
            () => goto(
              () => showSingleDetail(
                context,
                'RSI',
                () => cfg.rsiPeriod,
                (v) => cfg.rsiPeriod = v,
                () => cfg.rsiColor,
                (c) => cfg.rsiColor = c,
                cfg.resetRsi,
                onChanged,
              ),
            ),
          ),
          item(
            'WR',
            S.current.indicatorWrDesc,
            () => goto(
              () => showSingleDetail(
                context,
                'WR',
                () => cfg.wrPeriod,
                (v) => cfg.wrPeriod = v,
                () => cfg.wrColor,
                (c) => cfg.wrColor = c,
                cfg.resetWr,
                onChanged,
              ),
            ),
          ),
          ...pro.indicatorItems(context, onChanged, group, item, goto),
          const SizedBox(height: 12),
        ],
      );
    },
    scrollable: true,
  );
}
