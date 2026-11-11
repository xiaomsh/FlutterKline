import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../l10n/l10n.dart';
import '../../pro/live_pro.dart';
import '../../widget/indicator_settings.dart';
import '../../widget/live_sheet.dart';
import '../../widget/live_style.dart';
import '../../widget/pro_lock.dart';
import 'live_controller.dart';

void showLiveSettings(BuildContext context, LiveController controller) {
  showLiveSheet(context, (ctx, setSheet) {
    Widget row(String title, Widget trailing, {bool locked = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: LiveStyle.textPrimary),
                  ),
                ),
                if (locked) const SizedBox(width: 4),
                if (locked) const ProLockIcon(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Long options (English time zones) truncate instead of pushing the row past the edge
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiveSheetTitleBar(title: S.current.liveChartSettings),
          const SizedBox(height: 8),
          row(
            S.current.liveIndicatorParams,
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showLiveIndicatorSettings(context, controller);
              },
              child: Text(S.current.liveGoToSettings),
            ),
          ),
          LiveSectionTitle(S.current.liveSectionDisplay),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: LiveCheckRow(
                    label: S.current.liveLastPrice,
                    value: controller.showPrice.value,
                    onChanged: controller.setShowPrice,
                  ),
                ),
                Expanded(
                  child: LiveCheckRow(
                    label: S.current.liveCountdown,
                    value: controller.showCountdown.value,
                    onChanged: (v) => controller.showCountdown.value = v,
                  ),
                ),
                Expanded(
                  child: LiveCheckRow(
                    label: S.current.liveBookPrice,
                    value: controller.showBookPrice.value,
                    onChanged: (v) => controller.showBookPrice.value = v,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: LiveCheckRow(
                    label: S.current.liveYAxisOutside,
                    value: controller.yAxisOutside.value,
                    onChanged: (v) => controller.yAxisOutside.value = v,
                  ),
                ),
                Expanded(
                  child: LiveCheckRow(
                    label: S.current.liveAutoFollow,
                    value: controller.autoFollow.value,
                    onChanged: (v) => controller.autoFollow.value = v,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          LiveSectionTitle(S.current.liveSectionChart),
          row(
            S.current.liveChartType,
            Obx(
              () => DropdownButton<String>(
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                value: controller.seriesKind.value,
                items: [
                  DropdownMenuItem(value: 'candle', child: Text(S.current.liveSeriesCandle)),
                  DropdownMenuItem(value: 'line', child: Text(S.current.liveSeriesLine)),
                  DropdownMenuItem(value: 'area', child: Text(S.current.liveSeriesArea)),
                  for (final e in LivePro.seriesNames.entries)
                    DropdownMenuItem(
                      value: e.key,
                      enabled: LivePro.unlocked,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (!LivePro.unlocked) const SizedBox(width: 4),
                          if (!LivePro.unlocked) const ProLockIcon(),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => controller.seriesKind.value = v ?? controller.seriesKind.value,
              ),
            ),
          ),
          row(
            S.current.liveHeikinAshi,
            Obx(
              () => Switch(
                value: controller.pro.heikinAshi.value,
                onChanged: (v) =>
                    LivePro.unlocked ? controller.pro.setHeikinAshi(v) : showProLock(),
              ),
            ),
            locked: !LivePro.unlocked,
          ),
          row(
            S.current.liveLogScale,
            Obx(
              () => Switch(
                value: controller.isLog.value,
                onChanged: (v) => controller.isLog.value = v,
              ),
            ),
          ),
          row(
            S.current.livePercentScale,
            Obx(
              () => Switch(
                value: controller.percent.value,
                onChanged: (v) => controller.percent.value = v,
              ),
            ),
          ),
          row(
            S.current.liveTimeZone,
            Obx(
              () => DropdownButton<String>(
                isExpanded: true,
                alignment: AlignmentDirectional.centerEnd,
                value: switch (controller.utcOffset.value) {
                  null => 'local',
                  Duration.zero => 'utc',
                  const Duration(hours: 8) => '+8',
                  _ => '-5',
                },
                items: [
                  DropdownMenuItem(value: 'local', child: Text(S.current.liveTimeZoneDevice)),
                  const DropdownMenuItem(value: 'utc', child: Text('UTC')),
                  DropdownMenuItem(value: '+8', child: Text(S.current.liveTimeZoneShanghai)),
                  DropdownMenuItem(value: '-5', child: Text(S.current.liveTimeZoneNewYork)),
                ],
                onChanged: (key) => controller.utcOffset.value = switch (key) {
                  'utc' => Duration.zero,
                  '+8' => const Duration(hours: 8),
                  '-5' => const Duration(hours: -5),
                  _ => null,
                },
              ),
            ),
          ),
          LiveSectionTitle(S.current.liveSectionChartHeight),
          Obx(
            () => Slider(
              value: controller.chartHeight.value,
              min: 240,
              max: 400,
              activeColor: LiveStyle.brand,
              onChanged: (v) => controller.chartHeight.value = v,
            ),
          ),
        ],
      ),
    );
    // scrollable: the settings exceed showModalBottomSheet's default half-screen cap and would
    // overflow (RenderFlex) on small screens
  }, scrollable: true);
}

void showLiveIndicatorSettings(BuildContext context, LiveController controller) {
  showIndicatorSettings(
    context,
    controller.indicatorCfg,
    controller.pro,
    controller.applyIndicatorSettings,
  );
}
